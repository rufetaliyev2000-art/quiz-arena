import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Match, MatchType, MatchStatus } from '../database/entities/match.entity';
import { MatchPlayer } from '../database/entities/match-player.entity';
import { User } from '../database/entities/user.entity';

export interface PlayerResult {
  userId: string;
  score: number;
  correctAnswers: number;
}

export interface MatchResult {
  winnerId: string | null;
  isDraw: boolean;
  eloChange: Record<string, number>;
  newElo: Record<string, number>;
  rewards: Record<string, { xp: number; coins: number }>;
}

@Injectable()
export class MatchesService {
  constructor(
    @InjectRepository(Match) private matchesRepo: Repository<Match>,
    @InjectRepository(MatchPlayer) private playersRepo: Repository<MatchPlayer>,
    @InjectRepository(User) private usersRepo: Repository<User>,
  ) {}

  async createMatch(type: MatchType): Promise<Match> {
    const match = this.matchesRepo.create({ type, status: MatchStatus.IN_PROGRESS });
    return this.matchesRepo.save(match);
  }

  /**
   * Profil ekranı üçün son 20 matçı qaytarır. Hər matçda:
   * - özünün score-u
   * - rəqibin username + score (1v1 üçün; bot/solo üçün rəqib null)
   * - matçın nəticəsi (win/loss/draw)
   * - matchın tipi və bitmə vaxtı
   */
  async getUserMatches(userId: string) {
    const myEntries = await this.playersRepo.find({
      where: { user: { id: userId } },
      relations: ['match', 'match.winner'],
      order: { match: { started_at: 'DESC' } },
      take: 20,
    });

    const result: any[] = [];
    for (const me of myEntries) {
      // Match-ın bütün oyunçularını al (rəqibi tapmaq üçün)
      const allPlayers = await this.playersRepo.find({
        where: { match: { id: me.match.id } },
        relations: ['user'],
      });
      const opponent = allPlayers.find(p => p.user.id !== userId);
      const winnerId = me.match.winner?.id ?? null;
      let outcome: 'win' | 'loss' | 'draw' | 'solo' = 'solo';
      if (me.match.type === '1v1' && winnerId !== null) {
        outcome = winnerId === userId ? 'win' : 'loss';
      } else if (me.match.type === '1v1' && winnerId === null && me.match.status === 'finished') {
        outcome = 'draw';
      }
      result.push({
        matchId: me.match.id,
        type: me.match.type,
        status: me.match.status,
        startedAt: me.match.started_at,
        endedAt: me.match.ended_at,
        outcome,
        myScore: me.score,
        myCorrect: me.correct_answers,
        opponent: opponent ? {
          userId: opponent.user.id,
          username: opponent.user.username,
          score: opponent.score,
          correctAnswers: opponent.correct_answers,
        } : null,
      });
    }
    return result;
  }

  async finishOneVsOne(
    matchId: string,
    playerA: PlayerResult,
    playerB: PlayerResult,
  ): Promise<MatchResult> {
    const userA = await this.usersRepo.findOne({ where: { id: playerA.userId } });
    const userB = await this.usersRepo.findOne({ where: { id: playerB.userId } });
    if (!userA || !userB) {
      throw new Error('Players not found');
    }

    const isDraw = playerA.score === playerB.score;
    const winnerId = isDraw ? null : (playerA.score > playerB.score ? userA.id : userB.id);

    // ELO hesabla (K=32)
    const expectedA = 1 / (1 + Math.pow(10, (userB.elo - userA.elo) / 400));
    const expectedB = 1 - expectedA;
    const actualA = isDraw ? 0.5 : (winnerId === userA.id ? 1 : 0);
    const actualB = 1 - actualA;
    const k = 32;
    const deltaA = Math.round(k * (actualA - expectedA));
    const deltaB = Math.round(k * (actualB - expectedB));

    const newEloA = Math.max(0, userA.elo + deltaA);
    const newEloB = Math.max(0, userB.elo + deltaB);

    // Mükafatlar
    const rewardA = this.calculateReward(actualA, playerA.correctAnswers);
    const rewardB = this.calculateReward(actualB, playerB.correctAnswers);

    // Match yenilə
    await this.matchesRepo.update(matchId, {
      status: MatchStatus.FINISHED,
      ...(winnerId ? { winner: { id: winnerId } as User } : {}),
      ended_at: new Date(),
    });

    // MatchPlayer-lər
    await this.playersRepo.save([
      this.playersRepo.create({
        match: { id: matchId } as Match,
        user: { id: userA.id } as User,
        score: playerA.score,
        correct_answers: playerA.correctAnswers,
      }),
      this.playersRepo.create({
        match: { id: matchId } as Match,
        user: { id: userB.id } as User,
        score: playerB.score,
        correct_answers: playerB.correctAnswers,
      }),
    ]);

    // User stats yenilə
    await this.usersRepo.update(userA.id, {
      elo: newEloA,
      xp: userA.xp + rewardA.xp,
      coins: userA.coins + rewardA.coins,
      wins: userA.wins + (winnerId === userA.id ? 1 : 0),
      losses: userA.losses + (winnerId === userB.id ? 1 : 0),
      level: this.computeLevel(userA.xp + rewardA.xp),
    });
    await this.usersRepo.update(userB.id, {
      elo: newEloB,
      xp: userB.xp + rewardB.xp,
      coins: userB.coins + rewardB.coins,
      wins: userB.wins + (winnerId === userB.id ? 1 : 0),
      losses: userB.losses + (winnerId === userA.id ? 1 : 0),
      level: this.computeLevel(userB.xp + rewardB.xp),
    });

    return {
      winnerId,
      isDraw,
      eloChange: { [userA.id]: deltaA, [userB.id]: deltaB },
      newElo: { [userA.id]: newEloA, [userB.id]: newEloB },
      rewards: { [userA.id]: rewardA, [userB.id]: rewardB },
    };
  }

  /**
   * Quadratic level curve:
   * - Lv n → n+1 üçün n*1000 XP lazımdır
   * - Lv N-ə çatmaq üçün cəmi 500 * N * (N-1) XP
   * - Max səviyyə 100; XP davam edə bilər, level dayanır
   */
  private computeLevel(totalXp: number): number {
    if (totalXp <= 0) return 1;
    const n = Math.floor((1 + Math.sqrt(1 + (8 * totalXp) / 1000)) / 2);
    return Math.min(100, Math.max(1, n));
  }

  private calculateReward(outcome: number, correctAnswers: number) {
    // outcome: 1 = win, 0.5 = draw, 0 = loss
    const baseXp = outcome === 1 ? 200 : (outcome === 0.5 ? 100 : 50);
    const baseCoins = outcome === 1 ? 150 : (outcome === 0.5 ? 75 : 25);
    return {
      xp: baseXp + correctAnswers * 10,
      coins: baseCoins + correctAnswers * 5,
    };
  }
}
