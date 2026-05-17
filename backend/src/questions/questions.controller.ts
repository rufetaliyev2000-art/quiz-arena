import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { QuestionsService } from './questions.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { DeviceGuard } from '../auth/guards/device.guard';

@Controller('questions')
@UseGuards(JwtAuthGuard, DeviceGuard)
export class QuestionsController {
  constructor(private questionsService: QuestionsService) {}

  @Get('random')
  getRandom(@Query('count') count = '10', @Query('category') categoryId?: string) {
    return this.questionsService.getRandomQuestions(+count, categoryId);
  }

  @Get('categories')
  getCategories() {
    return this.questionsService.getCategories();
  }
}
