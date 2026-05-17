import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../database/entities/user.entity';

@Injectable()
export class LeaderboardService {
  constructor(@InjectRepository(User) private usersRepo: Repository<User>) {}

  async getTopPlayers(limit = 50) {
    return this.usersRepo.find({
      select: ['id', 'username', 'avatar', 'elo', 'wins', 'losses', 'level'],
      order: { elo: 'DESC' },
      take: limit,
    });
  }
}
