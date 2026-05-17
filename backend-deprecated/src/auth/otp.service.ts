import { Injectable } from '@nestjs/common';
import { EmailService } from './email.service';

interface OtpRecord {
  code: string;
  expiresAt: number;
  attempts: number;
}

@Injectable()
export class OtpService {
  private readonly otps = new Map<string, OtpRecord>();
  private readonly ttlMs = 10 * 60 * 1000; // 10 minutes
  private readonly maxAttempts = 5;

  constructor(private email: EmailService) {}

  private generateCode(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }

  async send(emailAddress: string): Promise<void> {
    const code = this.generateCode();
    const expiresAt = Date.now() + this.ttlMs;
    this.otps.set(emailAddress.toLowerCase(), { code, expiresAt, attempts: 0 });
    await this.email.sendOtp(emailAddress, code);
  }

  verify(emailAddress: string, code: string): { ok: boolean; reason?: string } {
    const key = emailAddress.toLowerCase();
    const rec = this.otps.get(key);
    if (!rec) return { ok: false, reason: 'no_otp' };
    if (rec.expiresAt < Date.now()) {
      this.otps.delete(key);
      return { ok: false, reason: 'expired' };
    }
    rec.attempts++;
    if (rec.attempts > this.maxAttempts) {
      this.otps.delete(key);
      return { ok: false, reason: 'too_many' };
    }
    if (rec.code !== code.trim()) return { ok: false, reason: 'mismatch' };
    this.otps.delete(key);
    return { ok: true };
  }

  has(emailAddress: string): boolean {
    const rec = this.otps.get(emailAddress.toLowerCase());
    if (!rec) return false;
    if (rec.expiresAt < Date.now()) {
      this.otps.delete(emailAddress.toLowerCase());
      return false;
    }
    return true;
  }
}
