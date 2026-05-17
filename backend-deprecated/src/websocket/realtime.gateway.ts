import {
  WebSocketGateway, WebSocketServer, SubscribeMessage,
  OnGatewayConnection, OnGatewayDisconnect, ConnectedSocket, MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Injectable } from '@nestjs/common';

/**
 * İstifadəçiyə yönəlik push hadisələri üçün. Hər user `presence:join` ilə
 * öz `user:{id}` otağına qoşulur. Backend (məs. FriendsService) bu Gateway-i
 * inject edib `pushToUser(id, event, data)` ilə hadisə yayır.
 */
@Injectable()
@WebSocketGateway({ cors: { origin: '*' }, namespace: '/realtime' })
export class RealtimeGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer() server: Server;

  // socketId → userId, ki disconnect-də təmizləyə bilək
  private socketToUser = new Map<string, string>();

  handleConnection(client: Socket) {
    console.log(`[RT] connected ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    const uid = this.socketToUser.get(client.id);
    this.socketToUser.delete(client.id);
    console.log(`[RT] disconnected ${client.id} (user=${uid?.slice(0, 8)})`);
  }

  @SubscribeMessage('presence:join')
  join(@ConnectedSocket() client: Socket, @MessageBody() data: { userId: string }) {
    if (!data?.userId) return;
    const room = `user:${data.userId}`;
    client.join(room);
    this.socketToUser.set(client.id, data.userId);
    console.log(`[RT] ${client.id} joined ${room}`);
    client.emit('presence:joined', { ok: true });
  }

  /** İstifadəçiyə yönəlik push. Çağrılır digər service-lərdən. */
  pushToUser(userId: string, event: string, data: unknown) {
    this.server.to(`user:${userId}`).emit(event, data);
  }
}
