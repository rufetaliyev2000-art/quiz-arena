import {
  Controller, Get, Post, Delete, Param, Body, Request, UseGuards, Query,
} from '@nestjs/common';
import { FriendsService } from './friends.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { DeviceGuard } from '../auth/guards/device.guard';

@Controller('friends')
@UseGuards(JwtAuthGuard, DeviceGuard)
export class FriendsController {
  constructor(private friends: FriendsService) {}

  /// GET /friends/lookup?code=ABC123 — friend_code ilə profil tap.
  @Get('lookup')
  lookup(@Query('code') code: string) {
    return this.friends.findByCode(code ?? '');
  }

  /// GET /friends — accepted dostlar siyahısı.
  @Get()
  list(@Request() req) {
    return this.friends.listFriends(req.user.id);
  }

  /// GET /friends/pending — incoming + outgoing pending sorğular.
  @Get('pending')
  pending(@Request() req) {
    return this.friends.listPending(req.user.id);
  }

  /// GET /friends/blocked — bloklananlar.
  @Get('blocked')
  blocked(@Request() req) {
    return this.friends.listBlocked(req.user.id);
  }

  /// POST /friends/request — friend_code ilə sorğu göndər.
  @Post('request')
  send(@Request() req, @Body() body: { code: string }) {
    return this.friends.sendRequest(req.user.id, body.code);
  }

  /// POST /friends/:id/accept — gələn sorğunu qəbul et.
  @Post(':id/accept')
  accept(@Request() req, @Param('id') id: string) {
    return this.friends.acceptRequest(req.user.id, id);
  }

  /// DELETE /friends/:id — dostluğu sil / sorğunu rədd et.
  @Delete(':id')
  remove(@Request() req, @Param('id') id: string) {
    return this.friends.removeOrDecline(req.user.id, id);
  }

  /// POST /friends/block — friend_code ilə blok et.
  @Post('block')
  block(@Request() req, @Body() body: { code: string }) {
    return this.friends.block(req.user.id, body.code);
  }

  /// POST /friends/:id/unblock — blokdan çıxar.
  @Post(':id/unblock')
  unblock(@Request() req, @Param('id') id: string) {
    return this.friends.unblock(req.user.id, id);
  }
}
