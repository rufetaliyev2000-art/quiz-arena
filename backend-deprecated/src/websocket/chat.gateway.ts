import {
  WebSocketGateway, WebSocketServer, SubscribeMessage,
  OnGatewayConnection, OnGatewayDisconnect, ConnectedSocket, MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { FriendsService } from '../friends/friends.service';

interface ChatMessage {
  id: string;
  fromUserId: string;
  text: string;
  sentAt: number;
}

/**
 * Ephemeral 1:1 chat:
 *   - chatId deterministik = sorted([userA, userB]).join(':')
 *   - mesajlar yalnız memory-də saxlanır
 *   - hər iki tərəf chat-i bağladıqda (chat:close emit və ya disconnect)
 *     səssiya silinir
 *   - 1 saat boşluqdan sonra avtomatik təmizlik
 */
@WebSocketGateway({ cors: { origin: '*' }, namespace: '/chat' })
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer() server: Server;

  // chatId → { messages, activeSockets: Set<socketId>, lastTouch: number }
  private chats = new Map<string, {
    messages: ChatMessage[];
    activeSockets: Map<string, string>; // socketId → userId
    lastTouch: number;
  }>();

  // socketId → { userId, chatIds }
  private socketMeta = new Map<string, { userId: string; chatIds: Set<string> }>();

  private cleanupTimer?: NodeJS.Timeout;

  constructor(private friendsService: FriendsService) {
    // Hər 10 dəqiqədə bir 1 saat aktivlik olmayan chat-ləri sil
    this.cleanupTimer = setInterval(() => this.cleanup(), 10 * 60 * 1000);
  }

  private cleanup() {
    const now = Date.now();
    const stale = 60 * 60 * 1000;
    for (const [chatId, c] of this.chats) {
      if (c.activeSockets.size === 0 && now - c.lastTouch > stale) {
        this.chats.delete(chatId);
      }
    }
  }

  handleConnection(client: Socket) {
    console.log(`[CHAT] connected ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    const meta = this.socketMeta.get(client.id);
    if (!meta) return;
    for (const chatId of meta.chatIds) {
      const c = this.chats.get(chatId);
      if (!c) continue;
      c.activeSockets.delete(client.id);
      // Əgər heç kim qalmadısa, sessiyanı dərhal sil (mesajlar gedir)
      if (c.activeSockets.size === 0) {
        this.chats.delete(chatId);
        console.log(`[CHAT] session closed (empty): ${chatId}`);
      } else {
        // Qarşı tərəfə xəbər ver
        this.server.to(chatId).emit('chat:peer-left');
      }
    }
    this.socketMeta.delete(client.id);
    console.log(`[CHAT] disconnected ${client.id}`);
  }

  private chatIdFor(a: string, b: string): string {
    return [a, b].sort().join(':');
  }

  @SubscribeMessage('chat:open')
  async open(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { userId: string; peerId: string },
  ) {
    if (!data?.userId || !data?.peerId || data.userId === data.peerId) {
      client.emit('chat:error', { code: 'invalid_args' });
      return;
    }
    // Dostluq yoxlaması — yalnız dostlar mesajlaşa bilər
    const allowed = await this.friendsService.areFriends(data.userId, data.peerId);
    if (!allowed) {
      client.emit('chat:error', { code: 'not_friends' });
      return;
    }

    const chatId = this.chatIdFor(data.userId, data.peerId);
    client.join(chatId);

    let c = this.chats.get(chatId);
    if (!c) {
      c = { messages: [], activeSockets: new Map(), lastTouch: Date.now() };
      this.chats.set(chatId, c);
    }
    c.activeSockets.set(client.id, data.userId);
    c.lastTouch = Date.now();

    let meta = this.socketMeta.get(client.id);
    if (!meta) {
      meta = { userId: data.userId, chatIds: new Set() };
      this.socketMeta.set(client.id, meta);
    }
    meta.chatIds.add(chatId);

    // Mövcud aktiv mesajları göndər (peer hələ də sessiyadadırsa)
    client.emit('chat:opened', {
      chatId,
      messages: c.messages,
      peerOnline: Array.from(c.activeSockets.values()).some(u => u === data.peerId),
    });
    // Qarşı tərəfə "online" sinyalı
    client.to(chatId).emit('chat:peer-joined');
  }

  @SubscribeMessage('chat:send')
  send(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { chatId: string; text: string },
  ) {
    const c = this.chats.get(data.chatId);
    if (!c) {
      client.emit('chat:error', { code: 'no_session' });
      return;
    }
    const fromUserId = c.activeSockets.get(client.id);
    if (!fromUserId) {
      client.emit('chat:error', { code: 'not_in_chat' });
      return;
    }
    const text = (data.text ?? '').toString().slice(0, 1000).trim();
    if (!text) return;
    const msg: ChatMessage = {
      id: `${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
      fromUserId,
      text,
      sentAt: Date.now(),
    };
    c.messages.push(msg);
    c.lastTouch = msg.sentAt;
    // Otağa yaymaq (göndərənə də gedir ki, UI-da təsdiq olsun)
    this.server.to(data.chatId).emit('chat:message', msg);
  }

  /// Aktiv yazırammı/dayandırdım siqnalı (qarşı tərəfə "yazır..." göstərmək üçün).
  @SubscribeMessage('chat:typing')
  typing(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { chatId: string; isTyping: boolean },
  ) {
    client.to(data.chatId).emit('chat:typing', { isTyping: !!data?.isTyping });
  }

  /// İstifadəçi ekrandan çıxır — sessiyanı bağla. Əgər təkdir, mesajlar yox olur.
  @SubscribeMessage('chat:close')
  close(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { chatId: string },
  ) {
    const c = this.chats.get(data.chatId);
    if (!c) return;
    c.activeSockets.delete(client.id);
    client.leave(data.chatId);
    const meta = this.socketMeta.get(client.id);
    if (meta) meta.chatIds.delete(data.chatId);

    if (c.activeSockets.size === 0) {
      this.chats.delete(data.chatId);
      console.log(`[CHAT] session closed (manual): ${data.chatId}`);
    } else {
      this.server.to(data.chatId).emit('chat:peer-left');
    }
  }
}
