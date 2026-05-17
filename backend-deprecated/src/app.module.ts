import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { QuestionsModule } from './questions/questions.module';
import { MatchesModule } from './matches/matches.module';
import { LeaderboardModule } from './leaderboard/leaderboard.module';
import { WebsocketModule } from './websocket/websocket.module';
import { AdminModule } from './admin/admin.module';
import { FriendsModule } from './friends/friends.module';
import { User } from './database/entities/user.entity';
import { Category } from './database/entities/category.entity';
import { Question } from './database/entities/question.entity';
import { Match } from './database/entities/match.entity';
import { MatchPlayer } from './database/entities/match-player.entity';
import { Leaderboard } from './database/entities/leaderboard.entity';
import { Friendship } from './database/entities/friendship.entity';
import { DbBootstrapService } from './database/db-bootstrap.service';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        let dbUrl = config.get<string>('DATABASE_URL');
        const entities = [User, Category, Question, Match, MatchPlayer, Leaderboard, Friendship];
        if (dbUrl) {
          // Supabase: pooler 6543 (transaction) → 5432 (session) for DDL/synchronize
          dbUrl = dbUrl.replace(':6543/', ':5432/');
          return {
            type: 'postgres',
            url: dbUrl,
            ssl: { rejectUnauthorized: false },
            entities,
            synchronize: true,
            logging: false,
          } as any;
        }
        return {
          type: 'postgres',
          host: config.get<string>('DATABASE_HOST'),
          port: +(config.get<string>('DATABASE_PORT') ?? 5432),
          database: config.get<string>('DATABASE_NAME'),
          username: config.get<string>('DATABASE_USER'),
          password: config.get<string>('DATABASE_PASSWORD'),
          entities,
          synchronize: config.get('NODE_ENV') === 'development',
          logging: false,
        } as any;
      },
    }),
    AuthModule,
    UsersModule,
    QuestionsModule,
    MatchesModule,
    LeaderboardModule,
    FriendsModule,
    WebsocketModule,
    AdminModule,
  ],
  providers: [DbBootstrapService],
})
export class AppModule {}
