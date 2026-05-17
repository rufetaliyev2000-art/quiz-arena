import {
  Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn,
} from 'typeorm';
import { User } from './user.entity';

@Entity('leaderboard')
export class Leaderboard {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column()
  rank: number;

  @Column()
  points: number;

  @Column()
  season: number;
}
