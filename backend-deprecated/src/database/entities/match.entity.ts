import {
  Entity, PrimaryGeneratedColumn, Column, OneToMany,
  ManyToOne, JoinColumn, CreateDateColumn,
} from 'typeorm';
import { User } from './user.entity';

export enum MatchType {
  SOLO = 'solo',
  ONE_VS_ONE = '1v1',
  TOURNAMENT = 'tournament',
}

export enum MatchStatus {
  WAITING = 'waiting',
  IN_PROGRESS = 'in_progress',
  FINISHED = 'finished',
  CANCELLED = 'cancelled',
}

@Entity('matches')
export class Match {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'enum', enum: MatchType })
  type: MatchType;

  @Column({ type: 'enum', enum: MatchStatus, default: MatchStatus.WAITING })
  status: MatchStatus;

  @ManyToOne(() => User, { nullable: true })
  @JoinColumn({ name: 'winner_id' })
  winner: User;

  @CreateDateColumn()
  started_at: Date;

  @Column({ nullable: true })
  ended_at: Date;
}
