import { Module } from '@nestjs/common';
import { GameGateway } from './game.gateway';
import { ChatGateway } from './chat.gateway';
import { MatchesModule } from '../matches/matches.module';
import { QuestionsModule } from '../questions/questions.module';
import { FriendsModule } from '../friends/friends.module';
import { RealtimeModule } from './realtime.module';

@Module({
  imports: [MatchesModule, QuestionsModule, FriendsModule, RealtimeModule],
  providers: [GameGateway, ChatGateway],
})
export class WebsocketModule {}
