import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn,
  OneToMany, Index,
} from 'typeorm';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index({ unique: true })
  @Column({ length: 30 })
  username: string;

  @Index({ unique: true })
  @Column({ nullable: true })
  email: string;

  @Column({ nullable: true })
  phone: string;

  @Column({ nullable: true, select: false })
  password_hash: string;

  @Column({ nullable: true })
  avatar: string;

  @Column({ default: 0 })
  xp: number;

  @Column({ default: 1 })
  level: number;

  @Column({ default: 0 })
  coins: number;

  @Column({ default: 1000 })
  elo: number;

  @Column({ default: 0 })
  wins: number;

  @Column({ default: 0 })
  losses: number;

  @Column({ default: false })
  is_premium: boolean;

  @Column({ default: false })
  email_verified: boolean;

  @Column({ default: false })
  username_set: boolean;

  /// Qeydiyyat axınında istifadəçi adından əvvəl email OTP təsdiqini bağlayan
  /// bayraq. Sosial giriş email-i təmin edir, OTP gguiz-in öz təsdiqidir.
  @Column({ default: false })
  signup_otp_verified: boolean;

  /// Hal-hazırda bağlı yeganə cihazın UUID-i. Hər autentificirovanlanmış
  /// sorğunun `X-Device-Id` başlığı bu sahə ilə uyğun olmalıdır. Boşdursa
  /// (məs. yeni qeydiyyat) növbəti uğurlu OTP claim cihazı qeyd edir.
  @Column({ nullable: true })
  active_device_id: string | null;

  @Column({ nullable: true })
  active_device_label: string | null;

  @Column({ nullable: true, type: 'timestamp' })
  active_device_claimed_at: Date | null;

  @Column({ nullable: true })
  google_id: string;

  @Column({ nullable: true })
  apple_id: string;

  @Column({ nullable: true })
  facebook_id: string;

  @Column({ nullable: true, type: 'text' })
  refresh_token: string | null;

  @Index({ unique: true })
  @Column({ length: 6 })
  friend_code: string;

  @CreateDateColumn()
  created_at: Date;
}
