import {
  Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn,
  Index, CreateDateColumn, UpdateDateColumn, Unique, Check,
} from 'typeorm';
import { User } from './user.entity';

export type FriendshipStatus = 'pending' | 'accepted' | 'blocked';

@Entity('friendships')
@Unique('friendships_unique_pair', ['requester_id', 'addressee_id'])
@Check('friendships_no_self', 'requester_id <> addressee_id')
export class Friendship {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column('uuid')
  requester_id: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'requester_id' })
  requester: User;

  @Column('uuid')
  addressee_id: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'addressee_id' })
  addressee: User;

  @Index()
  @Column({ length: 16 })
  status: FriendshipStatus;

  @CreateDateColumn({ type: 'timestamptz' })
  created_at: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updated_at: Date;
}
