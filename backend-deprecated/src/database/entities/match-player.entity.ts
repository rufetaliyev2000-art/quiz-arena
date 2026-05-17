import {
  Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn,
} from 'typeorm';
import { Match } from './match.entity';
import { User } from './user.entity';

@Entity('match_players')
export class MatchPlayer {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Match)
  @JoinColumn({ name: 'match_id' })
  match: Match;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ default: 0 })
  score: number;

  @Column({ default: 0 })
  correct_answers: number;

  @Column({ type: 'float', default: 0 })
  answer_speed: number;
}
