import {
  WebSocketGateway, WebSocketServer, SubscribeMessage,
  OnGatewayConnection, OnGatewayDisconnect, ConnectedSocket, MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { MatchesService, PlayerResult } from '../matches/matches.service';
import { QuestionsService } from '../questions/questions.service';
import { MatchType } from '../database/entities/match.entity';

interface PlayerCustomization {
  avatarEmoji?: string | null;
  frameId?: string;
  colorId?: string;
}

interface WaitingPlayer {
  socketId: string;
  userId: string;
  username: string;
  elo: number;
  friendCode: string;
  customization: PlayerCustomization;
  joinedAt: number; // ms timestamp — ELO toleransını vaxt keçdikcə genişlətmək üçün
}

/**
 * ELO toleransını gözləmə müddətinə görə hesabla:
 *   0-10s  → ±100
 *   10-30s → ±250
 *   30-60s → ±500
 *   60s+   → ±1000 (praktikada hər kəs uyğun olur)
 *
 * 100k istifadəçidə vacibdir ki, ELO yaxın oyunçular tez tapılsın, sonra
 * gözləmə artdıqda fərq də artsın. Hər iki tərəfin toleransının min-i kifayət
 * etməlidir ki, match qurulsun (qarşılıqlı razılıq).
 */
function eloToleranceFor(waitingMs: number): number {
  if (waitingMs < 10_000) return 100;
  if (waitingMs < 30_000) return 250;
  if (waitingMs < 60_000) return 500;
  return 1000;
}

interface ActiveMatch {
  matchId: string;
  players: { socketId: string; userId: string; username: string; elo: number; friendCode: string; customization: PlayerCustomization }[];
  questions: any[];
  results: Map<string, PlayerResult>;
}

@WebSocketGateway({ cors: { origin: '*' }, namespace: '/game' })
export class GameGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer() server: Server;

  private waitingPlayers: WaitingPlayer[] = [];
  private activeMatches = new Map<string, ActiveMatch>();
  private socketToMatch = new Map<string, string>();
  private rescanTimer?: NodeJS.Timeout;

  constructor(
    private matchesService: MatchesService,
    private questionsService: QuestionsService,
  ) {
    // Hər 5 saniyədə queue-ni yenidən yoxla — vaxt keçdikcə genişlənən ELO
    // toleransı yeni match imkanı yarada bilər (yeni heç kim gəlmədən belə
    // iki köhnə gözləyən bir-birini görə bilər).
    this.rescanTimer = setInterval(() => this.rescanQueue(), 5_000);
  }

  private async rescanQueue() {
    if (this.waitingPlayers.length < 2) return;
    const now = Date.now();
    for (let i = 0; i < this.waitingPlayers.length; i++) {
      const a = this.waitingPlayers[i];
      const aTol = eloToleranceFor(now - a.joinedAt);
      for (let j = i + 1; j < this.waitingPlayers.length; j++) {
        const b = this.waitingPlayers[j];
        const bTol = eloToleranceFor(now - b.joinedAt);
        if (Math.abs(a.elo - b.elo) <= Math.max(aTol, bTol)) {
          console.log(`[WS] rescan: pairing ${a.username} (waited ${Math.round((now - a.joinedAt) / 1000)}s) ↔ ${b.username} (waited ${Math.round((now - b.joinedAt) / 1000)}s)`);
          // İkisini də sil və match başlat
          this.waitingPlayers = this.waitingPlayers.filter(p => p.userId !== a.userId && p.userId !== b.userId);
          await this.startMatch(a, b);
          return; // bir match başladıqdan sonra növbəti tick-də davam
        }
      }
    }
  }

  handleConnection(client: Socket) {
    console.log(`[WS] Client connected: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    this.waitingPlayers = this.waitingPlayers.filter(p => p.socketId !== client.id);
    const matchId = this.socketToMatch.get(client.id);
    if (matchId) {
      // Yalnız qalan oyunçuya bildir (özünə yox)
      client.to(matchId).emit('opponent:disconnected');
      this.socketToMatch.delete(client.id);
      // Match-i təmizlə — qalan oyunçu match:complete göndərə bilməz
      const match = this.activeMatches.get(matchId);
      if (match) {
        for (const p of match.players) {
          this.socketToMatch.delete(p.socketId);
        }
        this.activeMatches.delete(matchId);
      }
    }
    console.log(`[WS] Client disconnected: ${client.id}`);
  }

  @SubscribeMessage('match:join')
  async handleJoinQueue(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { userId: string; username: string; elo: number; friendCode?: string; customization?: PlayerCustomization },
  ) {
    console.log(`[WS] match:join ← ${data.username} (id=${data.userId.slice(0, 8)}, elo=${data.elo}, sock=${client.id})`);
    console.log(`[WS]   queue=${this.waitingPlayers.length}, activeMatches=${this.activeMatches.size}`);

    // Eyni istifadəçi artıq oyundadır
    const inMatch = Array.from(this.activeMatches.values()).some(m =>
      m.players.some(p => p.userId === data.userId),
    );
    if (inMatch) {
      console.log(`[WS]   → REJECT: already in match`);
      client.emit('match:error', { message: 'ALREADY_IN_MATCH' });
      return;
    }

    // Eyni istifadəçi köhnə socket ilə queue-dadırsa — köhnəni təmizlə
    const existing = this.waitingPlayers.find(p => p.userId === data.userId);
    if (existing) {
      if (existing.socketId === client.id) {
        console.log(`[WS]   → already waiting on same socket, re-emit waiting`);
        client.emit('match:waiting');
        return;
      }
      console.log(`[WS]   → replace stale socket ${existing.socketId} → ${client.id}`);
      this.waitingPlayers = this.waitingPlayers.filter(p => p.userId !== data.userId);
    }

    // Yeni gələnin toleransı 0s = ±100. Gözləyənin toleransı isə artıq genişlənmiş ola bilər.
    // Match qurulması üçün hər iki tərəfin toleransının min-i ELO fərqini əhatə etməlidir.
    const now = Date.now();
    const opponent = this.waitingPlayers.find(p => {
      if (p.userId === data.userId) return false;
      const diff = Math.abs(p.elo - data.elo);
      const waitTol = eloToleranceFor(now - p.joinedAt);
      const myTol = eloToleranceFor(0); // yeni gələnin toleransı
      return diff <= Math.max(waitTol, myTol);
    });

    if (opponent) {
      console.log(`[WS]   → MATCH FOUND vs ${opponent.username} (elo diff=${Math.abs(opponent.elo - data.elo)}, waited ${Math.round((now - opponent.joinedAt) / 1000)}s)`);
      this.waitingPlayers = this.waitingPlayers.filter(p => p.userId !== opponent.userId);
      await this.startMatch(
        {
          socketId: client.id,
          userId: data.userId,
          username: data.username,
          elo: data.elo,
          friendCode: data.friendCode ?? '',
          customization: data.customization ?? {},
          joinedAt: now,
        },
        opponent,
      );
    } else {
      this.waitingPlayers.push({
        socketId: client.id,
        userId: data.userId,
        username: data.username,
        elo: data.elo,
        friendCode: data.friendCode ?? '',
        customization: data.customization ?? {},
        joinedAt: now,
      });
      console.log(`[WS]   → queued (total=${this.waitingPlayers.length}): ${this.waitingPlayers.map(p => `${p.username}(${p.elo})`).join(', ')}`);
      client.emit('match:waiting');
    }
  }

  @SubscribeMessage('match:cancel')
  handleCancel(@ConnectedSocket() client: Socket) {
    this.waitingPlayers = this.waitingPlayers.filter(p => p.socketId !== client.id);
  }

  @SubscribeMessage('answer:submit')
  handleAnswer(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: {
      matchId: string;
      questionIndex: number;
      answer: string;
      isCorrect: boolean;
      timeMs: number;
    },
  ) {
    // Yalnız rəqibə göndər (özünə echo yox)
    client.to(data.matchId).emit('answer:received', {
      socketId: client.id,
      questionIndex: data.questionIndex,
      answer: data.answer,
      isCorrect: data.isCorrect,
      timeMs: data.timeMs,
    });
  }

  @SubscribeMessage('match:complete')
  async handleComplete(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: {
      matchId: string;
      userId: string;
      score: number;
      correctAnswers: number;
    },
  ) {
    const match = this.activeMatches.get(data.matchId);
    if (!match) return;

    match.results.set(data.userId, {
      userId: data.userId,
      score: data.score,
      correctAnswers: data.correctAnswers,
    });

    if (match.results.size === 2) {
      const [a, b] = Array.from(match.results.values());
      try {
        const result = await this.matchesService.finishOneVsOne(data.matchId, a, b);
        this.server.to(data.matchId).emit('match:result', {
          ...result,
          scores: { [a.userId]: a.score, [b.userId]: b.score },
        });
      } catch (e) {
        console.error('[WS] finishOneVsOne failed:', e);
      } finally {
        this.activeMatches.delete(data.matchId);
        for (const p of match.players) {
          this.socketToMatch.delete(p.socketId);
        }
      }
    }
  }

  private async startMatch(playerA: WaitingPlayer, playerB: WaitingPlayer) {
    const match = await this.matchesService.createMatch(MatchType.ONE_VS_ONE);
    console.log(`[WS] START MATCH ${match.id.slice(0, 8)}: ${playerA.username} vs ${playerB.username}`);

    // Mobile-də 100 sual var (quiz_questions.dart). Backend yalnız index-ləri seçir.
    const totalQuestions = 100;
    const questionsPerMatch = 10;
    const indices = this.pickRandomIndices(questionsPerMatch, totalQuestions);

    const room = match.id;
    // @WebSocketGateway({ namespace: '/game' }) qoyulduqda `this.server`
    // runtime-da Namespace obyektinə yönəlir, lakin TS-də `Server` kimi typed-dir.
    // Namespace.sockets = Map<SocketId, Socket> — `any` cast ilə əldə edilir.
    const sockets = (this.server as any).sockets as Map<string, Socket>;
    sockets.get(playerA.socketId)?.join(room);
    sockets.get(playerB.socketId)?.join(room);

    this.activeMatches.set(match.id, {
      matchId: match.id,
      players: [playerA, playerB],
      questions: indices,
      results: new Map(),
    });
    this.socketToMatch.set(playerA.socketId, match.id);
    this.socketToMatch.set(playerB.socketId, match.id);

    this.server.to(room).emit('match:start', {
      matchId: match.id,
      questionIndices: indices,
      opponents: {
        [playerA.userId]: {
          userId: playerB.userId,
          username: playerB.username,
          elo: playerB.elo,
          friendCode: playerB.friendCode,
          customization: playerB.customization,
        },
        [playerB.userId]: {
          userId: playerA.userId,
          username: playerA.username,
          elo: playerA.elo,
          friendCode: playerA.friendCode,
          customization: playerA.customization,
        },
      },
    });
  }

  private pickRandomIndices(count: number, total: number): number[] {
    const all = Array.from({ length: total }, (_, i) => i);
    for (let i = all.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [all[i], all[j]] = [all[j], all[i]];
    }
    return all.slice(0, count);
  }
}
