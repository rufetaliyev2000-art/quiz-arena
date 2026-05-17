import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../database/entities/user.entity';

@Injectable()
export class UsersService {
  constructor(@InjectRepository(User) private repo: Repository<User>) {}

  async findById(id: string): Promise<User> {
    const user = await this.repo.findOne({ where: { id } });
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  async getProfile(id: string) {
    return this.findById(id);
  }

  async updateAvatar(id: string, avatar: string) {
    await this.repo.update(id, { avatar });
    return this.findById(id);
  }

  /// Username dəyişdirir. Başqa istifadəçidə tutulubsa Error('username_taken') atır.
  async changeUsername(id: string, username: string): Promise<User> {
    const existing = await this.repo.findOne({ where: { username } });
    if (existing && existing.id !== id) throw new Error('username_taken');
    await this.repo.update(id, { username, username_set: true });
    return this.findById(id);
  }

  /// Canlı yoxlama: bu username mövcuddur (özündən başqası onu götürübmü?).
  /// Selfdirsə (öz cari adı) `available: true` qaytarılır ki, save düyməsi
  /// aktiv qalsın.
  async isUsernameAvailable(id: string, username: string): Promise<boolean> {
    const existing = await this.repo.findOne({ where: { username } });
    if (!existing) return true;
    return existing.id === id;
  }

  async getLeaderboardPosition(id: string) {
    const user = await this.findById(id);
    return { elo: user.elo, wins: user.wins, losses: user.losses };
  }

  /**
   * Bot match / solo quiz / digər lokal oyunlardan qazanılan toplu mükafatı
   * backend-ə sinxronlaşdırır. Mobile-də lokal queue-da yığılan xp/coins/wins
   * ədədləri tək sorğu ilə göndərilir. ELO dəyişmir (yalnız real 1v1).
   */
  async applyLocalReward(
    id: string,
    payload: { xp?: number; coins?: number; wins?: number; losses?: number; draws?: number },
  ) {
    const user = await this.findById(id);
    const addXp = Math.max(0, Math.floor(payload.xp ?? 0));
    const addCoins = Math.max(0, Math.floor(payload.coins ?? 0));
    const addWins = Math.max(0, Math.floor(payload.wins ?? 0));
    const addLosses = Math.max(0, Math.floor(payload.losses ?? 0));
    // draws hələ DB-də saxlanılmır, gələcəkdə əlavə oluna bilər
    const newXp = user.xp + addXp;
    const newCoins = user.coins + addCoins;
    const newWins = user.wins + addWins;
    const newLosses = user.losses + addLosses;
    const newLevel = this.computeLevel(newXp);
    await this.repo.update(id, {
      xp: newXp,
      coins: newCoins,
      wins: newWins,
      losses: newLosses,
      level: newLevel,
    });
    return this.findById(id);
  }

  private computeLevel(totalXp: number): number {
    if (totalXp <= 0) return 1;
    const n = Math.floor((1 + Math.sqrt(1 + (8 * totalXp) / 1000)) / 2);
    return Math.min(100, Math.max(1, n));
  }
}
