import {
  Injectable, NotFoundException, ConflictException,
  BadRequestException, ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../database/entities/user.entity';
import { Friendship, FriendshipStatus } from '../database/entities/friendship.entity';
import { RealtimeGateway } from '../websocket/realtime.gateway';

@Injectable()
export class FriendsService {
  constructor(
    @InjectRepository(User) private users: Repository<User>,
    @InjectRepository(Friendship) private friendships: Repository<Friendship>,
    private realtime: RealtimeGateway,
  ) {}

  /** Hər iki tərəfə "siyahını yenilə" sinyalı göndər. */
  private notifyBoth(userA: string, userB: string) {
    this.realtime.pushToUser(userA, 'friends:changed', { at: Date.now() });
    this.realtime.pushToUser(userB, 'friends:changed', { at: Date.now() });
  }

  /// İstifadəçinin profilini friend_code ilə tap (özünü hesab tapsa belə qaytarır).
  async findByCode(code: string) {
    const normalized = code.trim().toUpperCase();
    if (!/^[A-Z2-9]{6}$/.test(normalized)) {
      throw new BadRequestException('invalid_code_format');
    }
    const user = await this.users.findOne({ where: { friend_code: normalized } });
    if (!user) throw new NotFoundException('user_not_found');
    return this.publicProfile(user);
  }

  /// Sorğu göndər. Əgər artıq pending/accepted varsa conflict, blocked varsa rədd.
  async sendRequest(requesterId: string, code: string) {
    const normalized = code.trim().toUpperCase();
    const target = await this.users.findOne({ where: { friend_code: normalized } });
    if (!target) throw new NotFoundException('user_not_found');
    if (target.id === requesterId) throw new BadRequestException('cannot_friend_self');

    // Bloklama yoxlaması (iki istiqamətdə)
    const blocked = await this.friendships.findOne({
      where: [
        { requester_id: target.id, addressee_id: requesterId, status: 'blocked' },
        { requester_id: requesterId, addressee_id: target.id, status: 'blocked' },
      ],
    });
    if (blocked) throw new ForbiddenException('blocked');

    // Hər iki istiqamətdə mövcud bağlantı yoxla
    const existing = await this.friendships.findOne({
      where: [
        { requester_id: requesterId, addressee_id: target.id },
        { requester_id: target.id, addressee_id: requesterId },
      ],
    });

    if (existing) {
      if (existing.status === 'accepted') {
        throw new ConflictException('already_friends');
      }
      if (existing.status === 'pending') {
        // Əgər qarşı tərəf bizə əvvəlcədən sorğu göndərmişsə — accept et
        if (existing.requester_id === target.id && existing.addressee_id === requesterId) {
          existing.status = 'accepted';
          await this.friendships.save(existing);
          this.notifyBoth(requesterId, target.id);
          return { id: existing.id, status: 'accepted' as FriendshipStatus };
        }
        throw new ConflictException('already_pending');
      }
    }

    const created = this.friendships.create({
      requester_id: requesterId,
      addressee_id: target.id,
      status: 'pending',
    });
    const saved = await this.friendships.save(created);
    this.notifyBoth(requesterId, target.id);
    return { id: saved.id, status: saved.status };
  }

  /// Mənə gələn sorğunu qəbul et.
  async acceptRequest(myId: string, friendshipId: string) {
    const f = await this.friendships.findOne({ where: { id: friendshipId } });
    if (!f) throw new NotFoundException('friendship_not_found');
    if (f.addressee_id !== myId) throw new ForbiddenException('not_your_request');
    if (f.status !== 'pending') throw new BadRequestException('not_pending');
    f.status = 'accepted';
    await this.friendships.save(f);
    this.notifyBoth(f.requester_id, f.addressee_id);
    return { id: f.id, status: f.status };
  }

  /// Sorğunu rədd et və ya silə (dost da silə bilər).
  async removeOrDecline(myId: string, friendshipId: string) {
    const f = await this.friendships.findOne({ where: { id: friendshipId } });
    if (!f) throw new NotFoundException('friendship_not_found');
    if (f.requester_id !== myId && f.addressee_id !== myId) {
      throw new ForbiddenException('not_yours');
    }
    const a = f.requester_id;
    const b = f.addressee_id;
    await this.friendships.delete(f.id);
    this.notifyBoth(a, b);
    return { ok: true };
  }

  /// İstifadəçini blok et (friend_code ilə). Əvvəlki bağlantı varsa update edir.
  async block(myId: string, code: string) {
    const normalized = code.trim().toUpperCase();
    const target = await this.users.findOne({ where: { friend_code: normalized } });
    if (!target) throw new NotFoundException('user_not_found');
    if (target.id === myId) throw new BadRequestException('cannot_block_self');

    let f = await this.friendships.findOne({
      where: [
        { requester_id: myId, addressee_id: target.id },
        { requester_id: target.id, addressee_id: myId },
      ],
    });

    if (!f) {
      f = this.friendships.create({
        requester_id: myId,
        addressee_id: target.id,
        status: 'blocked',
      });
    } else {
      // Blokçu həmişə "requester" tərəf olur ki, kimin bloklədiyi məlum olsun.
      f.requester_id = myId;
      f.addressee_id = target.id;
      f.status = 'blocked';
    }
    await this.friendships.save(f);
    this.notifyBoth(f.requester_id, f.addressee_id);
    return { id: f.id, status: f.status };
  }

  /// Blokdan çıxar.
  async unblock(myId: string, friendshipId: string) {
    const f = await this.friendships.findOne({ where: { id: friendshipId } });
    if (!f) throw new NotFoundException('friendship_not_found');
    if (f.status !== 'blocked') throw new BadRequestException('not_blocked');
    if (f.requester_id !== myId) throw new ForbiddenException('only_blocker_can_unblock');
    const a = f.requester_id;
    const b = f.addressee_id;
    await this.friendships.delete(f.id);
    this.notifyBoth(a, b);
    return { ok: true };
  }

  /// Dostlar siyahısı (accepted).
  async listFriends(myId: string) {
    const accepted = await this.friendships.find({
      where: [
        { requester_id: myId, status: 'accepted' },
        { addressee_id: myId, status: 'accepted' },
      ],
      relations: ['requester', 'addressee'],
      order: { updated_at: 'DESC' },
    });
    return accepted.map(f => {
      const other = f.requester_id === myId ? f.addressee : f.requester;
      return {
        friendshipId: f.id,
        ...this.publicProfile(other),
      };
    });
  }

  /// Mənə gələn (incoming) və mənim göndərdiyim (outgoing) pending sorğular.
  async listPending(myId: string) {
    const all = await this.friendships.find({
      where: [
        { requester_id: myId, status: 'pending' },
        { addressee_id: myId, status: 'pending' },
      ],
      relations: ['requester', 'addressee'],
      order: { created_at: 'DESC' },
    });
    const incoming = all
      .filter(f => f.addressee_id === myId)
      .map(f => ({ friendshipId: f.id, ...this.publicProfile(f.requester) }));
    const outgoing = all
      .filter(f => f.requester_id === myId)
      .map(f => ({ friendshipId: f.id, ...this.publicProfile(f.addressee) }));
    return { incoming, outgoing };
  }

  /// Bloklananlar (yalnız mənim blok etdiklərim).
  async listBlocked(myId: string) {
    const blocked = await this.friendships.find({
      where: { requester_id: myId, status: 'blocked' },
      relations: ['addressee'],
      order: { updated_at: 'DESC' },
    });
    return blocked.map(f => ({
      friendshipId: f.id,
      ...this.publicProfile(f.addressee),
    }));
  }

  /// İki istifadəçi arasında accepted dostluq varmı? (chat icazəsi üçün)
  async areFriends(aId: string, bId: string): Promise<boolean> {
    const f = await this.friendships.findOne({
      where: [
        { requester_id: aId, addressee_id: bId, status: 'accepted' },
        { requester_id: bId, addressee_id: aId, status: 'accepted' },
      ],
    });
    return !!f;
  }

  private publicProfile(u: User) {
    return {
      id: u.id,
      username: u.username,
      friend_code: u.friend_code,
      avatar: u.avatar,
      level: u.level,
      elo: u.elo,
    };
  }
}
