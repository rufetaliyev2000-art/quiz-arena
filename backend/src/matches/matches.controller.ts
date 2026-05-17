import { Controller, Get, UseGuards, Request } from '@nestjs/common';
import { MatchesService } from './matches.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { DeviceGuard } from '../auth/guards/device.guard';

@Controller('matches')
@UseGuards(JwtAuthGuard, DeviceGuard)
export class MatchesController {
  constructor(private matchesService: MatchesService) {}

  @Get('history')
  getHistory(@Request() req) {
    return this.matchesService.getUserMatches(req.user.id);
  }
}
