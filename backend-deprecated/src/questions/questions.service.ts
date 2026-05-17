import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Question, Difficulty } from '../database/entities/question.entity';
import { Category } from '../database/entities/category.entity';

@Injectable()
export class QuestionsService {
  constructor(
    @InjectRepository(Question) private questionsRepo: Repository<Question>,
    @InjectRepository(Category) private categoriesRepo: Repository<Category>,
  ) {}

  async getRandomQuestions(count: number, categoryId?: string, difficulty?: Difficulty) {
    const qb = this.questionsRepo.createQueryBuilder('q')
      .where('q.is_active = true')
      .orderBy('RANDOM()')
      .take(count);

    if (categoryId) qb.andWhere('q.category_id = :categoryId', { categoryId });
    if (difficulty) qb.andWhere('q.difficulty = :difficulty', { difficulty });

    return qb.getMany();
  }

  async getCategories() {
    return this.categoriesRepo.find();
  }
}
