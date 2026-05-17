import { Injectable, UnauthorizedException, ConflictException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { User } from '../database/entities/user.entity';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { OtpService } from './otp.service';

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User) private usersRepo: Repository<User>,
    private jwtService: JwtService,
    private config: ConfigService,
    private otp: OtpService,
  ) {}

  /// Qeydiyyat: OTP ləğv edildiyi üçün dərhal token qaytarır.
  async register(dto: RegisterDto) {
    const exists = await this.usersRepo.findOne({
      where: [{ username: dto.username }, { email: dto.email }],
    });
    if (exists) {
      throw new ConflictException('Username or email already taken');
    }

    const hash = await bcrypt.hash(dto.password, 12);
    const user = this.usersRepo.create({
      username: dto.username,
      email: dto.email,
      password_hash: hash,
      email_verified: true, // OTP axını ləğv edilib
    });
    await this.usersRepo.save(user);
    return this.generateTokens(user);
  }

  /// Step 2: User submits OTP code; on success returns tokens.
  async verifyOtp(email: string, code: string) {
    const result = this.otp.verify(email, code);
    if (!result.ok) {
      throw new BadRequestException('invalid_otp');
    }
    const user = await this.usersRepo.findOne({
      where: { email },
      select: ['id', 'username', 'email', 'xp', 'level', 'coins', 'elo', 'email_verified'],
    });
    if (!user) throw new UnauthorizedException();
    if (!user.email_verified) {
      await this.usersRepo.update(user.id, { email_verified: true });
      user.email_verified = true;
    }
    return this.generateTokens(user);
  }

  async resendOtp(email: string) {
    const user = await this.usersRepo.findOne({ where: { email } });
    if (!user) throw new UnauthorizedException('user_not_found');
    if (user.email_verified) throw new BadRequestException('already_verified');
    await this.otp.send(email);
    return { sent: true };
  }

  async login(dto: LoginDto) {
    const user = await this.usersRepo.findOne({
      where: [{ username: dto.identifier }, { email: dto.identifier }],
      select: ['id', 'username', 'email', 'password_hash', 'xp', 'level', 'coins', 'elo', 'email_verified'],
    });
    if (!user) throw new UnauthorizedException('Invalid credentials');

    const valid = await bcrypt.compare(dto.password, user.password_hash);
    if (!valid) throw new UnauthorizedException('Invalid credentials');

    // OTP/email verification ləğv edilib
    return this.generateTokens(user);
  }

  async refreshTokens(userId: string, refreshToken: string) {
    const user = await this.usersRepo.findOne({ where: { id: userId } });
    if (!user || !user.refresh_token) throw new UnauthorizedException();

    const valid = await bcrypt.compare(refreshToken, user.refresh_token);
    if (!valid) throw new UnauthorizedException('Invalid refresh token');

    return this.generateTokens(user);
  }

  async logout(userId: string) {
    await this.usersRepo.update(userId, { refresh_token: null });
  }

  // ──────── Sign-up OTP gate (sosial giriş sonrası, username-dən əvvəl) ────────

  async sendSignupOtp(userId: string) {
    const user = await this.usersRepo.findOne({ where: { id: userId } });
    if (!user) throw new UnauthorizedException('user_not_found');
    if (!user.email) throw new BadRequestException('no_email_on_profile');
    if (user.signup_otp_verified) return { sent: false, alreadyVerified: true };
    await this.otp.send(user.email);
    return { sent: true };
  }

  /// Sign-up OTP-i təsdiq edir VƏ ilk cihaz kimi qeyd edir. Bir əməliyyat —
  /// belə ki istifadəçi adı təyin etməyə getməzdən əvvəl artıq cihaz claim
  /// edilib və ikinci cihazdan giriş mümkün deyil.
  async verifySignupOtp(userId: string, code: string, deviceId: string, deviceLabel?: string) {
    const user = await this.usersRepo.findOne({ where: { id: userId } });
    if (!user) throw new UnauthorizedException('user_not_found');
    if (!user.email) throw new BadRequestException('no_email_on_profile');
    if (!deviceId?.trim()) throw new BadRequestException('missing_device_id');
    if (!user.signup_otp_verified) {
      const res = this.otp.verify(user.email, code);
      if (!res.ok) throw new BadRequestException(res.reason ?? 'invalid_otp');
    }
    await this.usersRepo.update(userId, {
      signup_otp_verified: true,
      email_verified: true,
      active_device_id: deviceId.trim(),
      active_device_label: (deviceLabel ?? '').trim() || null,
      active_device_claimed_at: new Date(),
    });
    return { verified: true, deviceClaimed: true };
  }

  // ──────── Device claim flow (ikinci cihazdan giriş) ────────

  async getDeviceStatus(userId: string, requestingDeviceId: string) {
    const user = await this.usersRepo.findOne({ where: { id: userId } });
    if (!user) throw new UnauthorizedException('user_not_found');
    const active = user.active_device_id;
    return {
      signupOtpVerified: user.signup_otp_verified,
      hasActiveDevice: !!active,
      currentIsActive: active != null && active === requestingDeviceId,
      activeDeviceLabel: user.active_device_label,
    };
  }

  /// Cari cihaz aktiv DEYİL — OTP göndər ki, istifadəçi bu cihazı claim etsin.
  async sendDeviceOtp(userId: string) {
    const user = await this.usersRepo.findOne({ where: { id: userId } });
    if (!user) throw new UnauthorizedException('user_not_found');
    if (!user.email) throw new BadRequestException('no_email_on_profile');
    await this.otp.send(user.email);
    return { sent: true };
  }

  /// OTP düzgündürsə active_device_id-ni bu cihaza yenilə. Köhnə cihaz növbəti
  /// API çağırışında 403 alacaq və FE onu çıxış edəcək.
  async claimDevice(userId: string, code: string, deviceId: string, deviceLabel?: string) {
    const user = await this.usersRepo.findOne({ where: { id: userId } });
    if (!user) throw new UnauthorizedException('user_not_found');
    if (!user.email) throw new BadRequestException('no_email_on_profile');
    if (!deviceId?.trim()) throw new BadRequestException('missing_device_id');
    const res = this.otp.verify(user.email, code);
    if (!res.ok) throw new BadRequestException(res.reason ?? 'invalid_otp');
    await this.usersRepo.update(userId, {
      active_device_id: deviceId.trim(),
      active_device_label: (deviceLabel ?? '').trim() || null,
      active_device_claimed_at: new Date(),
    });
    return { claimed: true };
  }

  private async generateTokens(user: User) {
    const payload = { sub: user.id, username: user.username };

    const accessToken = this.jwtService.sign(payload, {
      secret: this.config.get('JWT_SECRET'),
      expiresIn: this.config.get('JWT_EXPIRES_IN'),
    });

    const refreshToken = this.jwtService.sign(payload, {
      secret: this.config.get('JWT_REFRESH_SECRET'),
      expiresIn: this.config.get('JWT_REFRESH_EXPIRES_IN'),
    });

    const hashedRefresh = await bcrypt.hash(refreshToken, 10);
    await this.usersRepo.update(user.id, { refresh_token: hashedRefresh });

    return {
      access_token: accessToken,
      refresh_token: refreshToken,
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        xp: user.xp,
        level: user.level,
        coins: user.coins,
        elo: user.elo,
      },
    };
  }
}
