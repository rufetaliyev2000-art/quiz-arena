import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../../database/entities/user.entity';

/// JwtAuthGuard-dan SONRA işləyir. `req.user` artıq dolduruluı.
/// `X-Device-Id` başlığı user.active_device_id ilə uyğun deyilsə 403
/// `device_mismatch` qaytarır — köhnə cihaz avtomatik sign-out olacaq.
///
/// QEYD: aşağıdakı endpoint-lər bu guard-dan kənarda qalmalıdır:
///   POST /auth/send-signup-otp, POST /auth/verify-signup-otp,
///   GET  /auth/device-status,    POST /auth/send-device-otp,
///   POST /auth/claim-device,     POST /auth/logout.
/// Çünki yeni cihaz oraya çatmaq üçün hələ claim etməyib.
@Injectable()
export class DeviceGuard implements CanActivate {
  constructor(@InjectRepository(User) private usersRepo: Repository<User>) {}

  async canActivate(ctx: ExecutionContext): Promise<boolean> {
    const req = ctx.switchToHttp().getRequest();
    const userFromJwt = req.user as { id: string } | undefined;
    if (!userFromJwt) throw new UnauthorizedException('no_user');

    const incomingDeviceId = ((req.headers['x-device-id'] as string) ?? '').trim();
    if (!incomingDeviceId) {
      throw new ForbiddenException({ code: 'device_required' });
    }

    const user = await this.usersRepo.findOne({
      where: { id: userFromJwt.id },
      select: ['id', 'active_device_id', 'signup_otp_verified'],
    });
    if (!user) throw new UnauthorizedException('user_not_found');

    // Sign-up OTP-i hələ tamamlamayıbsa, cihaz hələ qeyd olunmayıb. Bu halda
    // /auth/verify-signup-otp ilə qeyd ediləcək; ona qədər digər endpoint-lər
    // (məs. /users/me) işləyə bilsin ki, FE redirect-i məntiqli olsun.
    if (!user.active_device_id) {
      return true;
    }

    if (user.active_device_id !== incomingDeviceId) {
      throw new ForbiddenException({ code: 'device_mismatch' });
    }
    return true;
  }
}
