import { Module } from '@nestjs/common';
import { LlmService } from './llm.service';
import { AiService } from './ai.service';
import { AiController } from './ai.controller';

@Module({
  controllers: [AiController],
  providers: [LlmService, AiService],
})
export class AiModule {}
