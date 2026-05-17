import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';

export interface SmtpStatus {
  configured: boolean;
  userMasked?: string;
  lastError?: string;
  lastErrorAt?: string;
  lastSendAt?: string;
}

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private transporter: nodemailer.Transporter | null = null;
  private smtpUser: string | undefined;
  private lastError?: string;
  private lastErrorAt?: string;
  private lastSendAt?: string;

  constructor(private config: ConfigService) {
    const user = this.config.get<string>('SMTP_USER');
    const pass = this.config.get<string>('SMTP_PASS');
    this.smtpUser = user;
    if (user && pass) {
      this.transporter = nodemailer.createTransport({
        host: 'smtp.gmail.com',
        port: 465,
        secure: true,
        auth: { user, pass },
      });
      this.logger.log(`SMTP configured for ${user}`);
    } else {
      this.logger.warn('SMTP_USER / SMTP_PASS env vars not set — emails will not be sent.');
    }
  }

  status(): SmtpStatus {
    const masked = this.smtpUser
      ? this.smtpUser.replace(/^(.{2}).+(@.+)$/, '$1***$2')
      : undefined;
    return {
      configured: !!this.transporter,
      userMasked: masked,
      lastError: this.lastError,
      lastErrorAt: this.lastErrorAt,
      lastSendAt: this.lastSendAt,
    };
  }

  async sendOtp(to: string, code: string): Promise<void> {
    if (!this.transporter) {
      this.logger.warn(`[EMAIL DISABLED] OTP for ${to}: ${code}`);
      return;
    }
    const from = this.smtpUser;
    const html = `
      <div style="font-family:-apple-system,system-ui,Segoe UI,Roboto,sans-serif;max-width:480px;margin:0 auto;padding:32px 24px;background:#0F1020;color:#fff;border-radius:16px;">
        <div style="text-align:center;margin-bottom:28px;">
          <div style="display:inline-block;width:72px;height:72px;background:linear-gradient(135deg,#361F9E,#7B5CFF 55%,#00E5FF);border-radius:20px;line-height:72px;font-size:36px;">⚡</div>
        </div>
        <h1 style="text-align:center;margin:0 0 8px;font-size:24px;font-weight:800;letter-spacing:1px;">GGUIZ BATTLE</h1>
        <p style="text-align:center;color:#9B9DB5;margin:0 0 32px;font-size:14px;letter-spacing:2px;">E-POÇT TƏSDİQİ</p>
        <div style="background:#1A1B30;border-radius:14px;padding:28px 24px;text-align:center;border:1px solid #2A2A50;">
          <p style="margin:0 0 14px;color:#B0B8D1;font-size:14px;">Təsdiq kodunuz:</p>
          <div style="font-size:42px;font-weight:900;letter-spacing:12px;color:#7B5CFF;font-family:'Courier New',monospace;">${code}</div>
          <p style="margin:18px 0 0;color:#6B7090;font-size:12px;">Kod 10 dəqiqə ərzində etibarlıdır</p>
        </div>
        <p style="text-align:center;color:#6B7090;font-size:12px;margin-top:28px;line-height:1.6;">
          Bu e-poçt sizin tərəfinizdən tələb edilməyibsə, onu nəzərə almayın.<br>
          Heç vaxt kodu kimsəyə paylaşmayın.
        </p>
        <p style="text-align:center;color:#3D4057;font-size:11px;margin-top:20px;">© 2026 Gguiz Battle</p>
      </div>
    `;
    try {
      await this.transporter.sendMail({
        from: `"Gguiz Battle" <${from}>`,
        to,
        subject: 'Gguiz Battle — Təsdiq kodunuz',
        html,
        text: `Gguiz Battle təsdiq kodu: ${code}\nKod 10 dəqiqə ərzində etibarlıdır.`,
      });
      this.lastSendAt = new Date().toISOString();
      this.lastError = undefined;
      this.lastErrorAt = undefined;
      this.logger.log(`OTP sent to ${to}`);
    } catch (e: any) {
      const msg = e?.message ?? String(e);
      this.lastError = msg;
      this.lastErrorAt = new Date().toISOString();
      this.logger.error(`Email send failed: ${msg}`);
      throw e;
    }
  }
}
