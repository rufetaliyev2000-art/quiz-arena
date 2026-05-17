import { Injectable, BadRequestException, UnauthorizedException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { OAuth2Client } from 'google-auth-library';
import { createRemoteJWKSet, jwtVerify } from 'jose';
import axios from 'axios';
import * as bcrypt from 'bcrypt';

import { User } from '../database/entities/user.entity';

interface SocialProfile {
  providerUserId: string;
  email?: string;
  name?: string;
  picture?: string;
}

type Provider = 'google' | 'apple' | 'facebook';

@Injectable()
export class SocialAuthService {
  private googleClient: OAuth2Client;
  private appleJwks: ReturnType<typeof createRemoteJWKSet>;

  constructor(
    @InjectRepository(User) private usersRepo: Repository<User>,
    private jwt: JwtService,
    private config: ConfigService,
  ) {
    this.googleClient = new OAuth2Client();
    this.appleJwks = createRemoteJWKSet(new URL('https://appleid.apple.com/auth/keys'));
  }

  // ───────── Provider verifiers ─────────

  /// Google ID token-i Google-un public açarları ilə təsdiqlə.
  async verifyGoogle(idToken: string): Promise<SocialProfile> {
    if (!idToken) throw new BadRequestException('id_token_required');
    try {
      const ticket = await this.googleClient.verifyIdToken({ idToken });
      const payload = ticket.getPayload();
      if (!payload?.sub) throw new Error('no_sub');
      return {
        providerUserId: payload.sub,
        email: payload.email,
        name: payload.name,
        picture: payload.picture,
      };
    } catch (e) {
      throw new UnauthorizedException('invalid_google_token');
    }
  }

  /// Google access_token ilə userinfo endpoint-i çağırıb istifadəçi profilini al.
  /// Android-də idToken çıxarmaq üçün serverClientId konfiqurə olunmadıqda istifadə olunur.
  async verifyGoogleAccessToken(accessToken: string): Promise<SocialProfile> {
    if (!accessToken) throw new BadRequestException('access_token_required');
    try {
      const r = await axios.get('https://openidconnect.googleapis.com/v1/userinfo', {
        headers: { Authorization: `Bearer ${accessToken}` },
        timeout: 10000,
      });
      const data = r.data as { sub: string; email?: string; name?: string; picture?: string };
      if (!data?.sub) throw new Error('no_sub');
      return {
        providerUserId: data.sub,
        email: data.email,
        name: data.name,
        picture: data.picture,
      };
    } catch (e) {
      throw new UnauthorizedException('invalid_google_token');
    }
  }

  /// Apple identity token-i Apple-ın JWKS-i ilə təsdiqlə.
  async verifyApple(identityToken: string): Promise<SocialProfile> {
    if (!identityToken) throw new BadRequestException('identity_token_required');
    const audience = this.config.get<string>('APPLE_SERVICE_ID');
    try {
      const { payload } = await jwtVerify(identityToken, this.appleJwks, {
        issuer: 'https://appleid.apple.com',
        ...(audience ? { audience } : {}),
      });
      if (!payload.sub) throw new Error('no_sub');
      return {
        providerUserId: String(payload.sub),
        email: typeof payload.email === 'string' ? payload.email : undefined,
      };
    } catch (e) {
      throw new UnauthorizedException('invalid_apple_token');
    }
  }

  /// Facebook access token-i Graph API ilə təsdiqlə.
  async verifyFacebook(accessToken: string): Promise<SocialProfile> {
    if (!accessToken) throw new BadRequestException('access_token_required');
    try {
      // Graph API: /me?fields=id,name,email,picture
      const r = await axios.get('https://graph.facebook.com/v18.0/me', {
        params: {
          access_token: accessToken,
          fields: 'id,name,email,picture',
        },
        timeout: 10000,
      });
      const data = r.data as { id: string; name?: string; email?: string; picture?: { data?: { url?: string } } };
      if (!data?.id) throw new Error('no_id');
      return {
        providerUserId: data.id,
        email: data.email,
        name: data.name,
        picture: data.picture?.data?.url,
      };
    } catch (e) {
      throw new UnauthorizedException('invalid_facebook_token');
    }
  }

  // ───────── Login/register flow ─────────

  /// Provider və token verildikdə: tokeni təsdiqlə, user-i tap və ya yarat,
  /// JWT qaytar. Eyni provider ID = eyni hesab (idempotent).
  /// [opts.googleAccessToken] true olduqda Google üçün userinfo endpoint istifadə olunur.
  async loginWith(
    provider: Provider,
    token: string,
    opts?: { googleAccessToken?: boolean },
  ) {
    let profile: SocialProfile;
    if (provider === 'google') {
      profile = opts?.googleAccessToken
        ? await this.verifyGoogleAccessToken(token)
        : await this.verifyGoogle(token);
    } else if (provider === 'apple') {
      profile = await this.verifyApple(token);
    } else if (provider === 'facebook') {
      profile = await this.verifyFacebook(token);
    } else {
      throw new BadRequestException('unknown_provider');
    }

    const { user, isNew, autoUsername } = await this.upsertUser(provider, profile);
    return this.issueTokens(user, { isNew, autoUsername, email: profile.email, name: profile.name, picture: profile.picture });
  }

  private async upsertUser(
    provider: Provider,
    profile: SocialProfile,
  ): Promise<{ user: User; isNew: boolean; autoUsername: boolean }> {
    const idCol = provider === 'google' ? 'google_id' : provider === 'apple' ? 'apple_id' : 'facebook_id';
    // 1) Provider ID-ə görə tap
    let user = await this.usersRepo.findOne({ where: { [idCol]: profile.providerUserId } as any });
    if (user) return { user, isNew: false, autoUsername: false };

    // 2) Eyni email başqa provider-də qeydiyyatdadırsa, hesabı linkləyirik
    if (profile.email) {
      user = await this.usersRepo.findOne({ where: { email: profile.email } });
      if (user) {
        await this.usersRepo.update(user.id, { [idCol]: profile.providerUserId, email_verified: true } as any);
        const refreshed = (await this.usersRepo.findOne({ where: { id: user.id } }))!;
        return { user: refreshed, isNew: false, autoUsername: false };
      }
    }

    // 3) Yeni istifadəçi yarat
    const username = await this.deriveUniqueUsername(profile.name, profile.email);
    const created = this.usersRepo.create({
      username,
      email: profile.email,
      avatar: profile.picture,
      email_verified: true,
      [idCol]: profile.providerUserId,
    } as any);
    const saved = await this.usersRepo.save(created as any) as User;
    return { user: saved, isNew: true, autoUsername: true };
  }

  private async deriveUniqueUsername(name?: string, email?: string): Promise<string> {
    const base = (name || email || 'player')
      .toLowerCase()
      .split('@')[0]
      .replace(/[^a-z0-9_]/g, '_')
      .replace(/^_+|_+$/g, '')
      .slice(0, 24) || 'player';
    let candidate = base;
    for (let i = 0; i < 10; i++) {
      const exists = await this.usersRepo.findOne({ where: { username: candidate } });
      if (!exists) return candidate;
      candidate = `${base}_${Math.floor(1000 + Math.random() * 9000)}`.slice(0, 30);
    }
    return `${base}_${Date.now().toString().slice(-6)}`;
  }

  private async issueTokens(
    user: User,
    extra?: { isNew?: boolean; autoUsername?: boolean; email?: string; name?: string; picture?: string },
  ) {
    const payload = { sub: user.id, username: user.username };
    const access = this.jwt.sign(payload, {
      secret: this.config.get('JWT_SECRET'),
      expiresIn: this.config.get('JWT_EXPIRES_IN'),
    });
    const refresh = this.jwt.sign(payload, {
      secret: this.config.get('JWT_REFRESH_SECRET'),
      expiresIn: this.config.get('JWT_REFRESH_EXPIRES_IN'),
    });
    const hashed = await bcrypt.hash(refresh, 10);
    await this.usersRepo.update(user.id, { refresh_token: hashed });
    return {
      access_token: access,
      refresh_token: refresh,
      is_new: extra?.isNew ?? false,
      auto_username: extra?.autoUsername ?? false,
      social_profile: extra?.email || extra?.name || extra?.picture
        ? {
            email: extra?.email ?? null,
            name: extra?.name ?? null,
            picture: extra?.picture ?? null,
          }
        : null,
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        avatar: user.avatar,
        xp: user.xp,
        level: user.level,
        coins: user.coins,
        elo: user.elo,
      },
    };
  }
}
