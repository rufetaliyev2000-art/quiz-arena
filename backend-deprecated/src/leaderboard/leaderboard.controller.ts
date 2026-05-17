import { Controller, Get, UseGuards } from '@nestjs/common';
import { LeaderboardService } from './leaderboard.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { DeviceGuard } from '../auth/guards/device.guard';

@Controller('leaderboard')
@UseGuards(JwtAuthGuard, DeviceGuard)
export class LeaderboardController {
  constructor(private leaderboardService: LeaderboardService) {}

  @Get()
  getTop() {
    return this.leaderboardService.getTopPlayers();
  }
}
