import { BadRequestException, Body, ConflictException, Controller, Get, Patch, Post, Query, UseGuards, Request } from '@nestjs/common';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { DeviceGuard } from '../auth/guards/device.guard';

@Controller('users')
@UseGuards(JwtAuthGuard, DeviceGuard)
export class UsersController {
  constructor(private usersService: UsersService) {}

  @Get('me')
  getMe(@Request() req) {
    return this.usersService.getProfile(req.user.id);
  }

  @Post('me/reward')
  applyReward(
    @Request() req,
    @Body() body: { xp?: number; coins?: number; wins?: number; losses?: number; draws?: number },
  ) {
    return this.usersService.applyLocalReward(req.user.id, body);
  }

  @Patch('me/username')
  async setUsername(@Request() req, @Body() body: { username?: string }) {
    const raw = (body?.username ?? '').trim();
    if (raw.length < 3) throw new BadRequestException('min_three_chars');
    if (!/^[a-zA-Z0-9_]+$/.test(raw)) throw new BadRequestException('username_format');
    try {
      return await this.usersService.changeUsername(req.user.id, raw);
    } catch (e: any) {
      if (e?.message === 'username_taken') throw new ConflictException('username_taken');
      throw e;
    }
  }

  /// Klient yazarkən canlı yoxlayır. Format də səhv olarsa
  /// `available=false, reason='format'` qaytarılır ki, UI dəqiq mesaj
  /// göstərsin.
  @Get('username-available')
  async checkUsername(@Request() req, @Query('name') name?: string) {
    const raw = (name ?? '').trim();
    if (raw.length < 3) return { available: false, reason: 'min_three_chars' };
    if (!/^[a-zA-Z0-9_]+$/.test(raw)) return { available: false, reason: 'format' };
    const available = await this.usersService.isUsernameAvailable(req.user.id, raw);
    return { available, reason: available ? null : 'taken' };
  }
}
