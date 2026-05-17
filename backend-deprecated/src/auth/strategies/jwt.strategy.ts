import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { passportJwtSecret } from 'jwks-rsa';
import { User } from '../../database/entities/user.entity';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    config: ConfigService,
    @InjectRepository(User) private usersRepo: Repository<User>,
  ) {
    const supabaseUrl = config.get<string>('SUPABASE_URL');
    if (!supabaseUrl) {
      throw new Error('SUPABASE_URL environment variable tələb olunur');
    }
    console.log('[JwtStrategy] init with SUPABASE_URL=', supabaseUrl);

    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      secretOrKeyProvider: passportJwtSecret({
        jwksUri: `${supabaseUrl}/auth/v1/.well-known/jwks.json`,
        cache: true,
        cacheMaxAge: 24 * 60 * 60 * 1000,
        rateLimit: true,
        jwksRequestsPerMinute: 10,
        handleSigningKeyError: (err, cb) => {
          console.error('[JwtStrategy] JWKS signing key error:', err?.message);
          return cb(err);
        },
      }),
      algorithms: ['ES256', 'RS256', 'HS256'],
      // Audience yoxlamasını söndürürük — Supabase aud="authenticated" amma
      // bəzən fərqli ola bilər, debug üçün bypass.
      ignoreExpiration: false,
    });
  }

  async validate(payload: any) {
    console.log('[JwtStrategy] validate called with payload:', JSON.stringify(payload).slice(0, 200));
    if (!payload?.sub) {
      console.error('[JwtStrategy] no sub in payload');
      throw new UnauthorizedException('no_sub');
    }
    const user = await this.usersRepo.findOne({ where: { id: payload.sub } });
    if (!user) {
      console.error('[JwtStrategy] profile not found for id=', payload.sub);
      throw new UnauthorizedException('profile_not_found');
    }
    console.log('[JwtStrategy] user found:', user.id, user.username);
    return user;
  }
}
