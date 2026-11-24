import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AiService } from './ai.service';
import { ChatDto, GenerarAlimentacionDto, GenerarRutinaDto } from './dto/ai.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import {
  CurrentUser,
  AuthenticatedUser,
} from '../common/decorators/current-user.decorator';

/** Todo opera sobre el usuario del token: nadie consulta la IA "como" otro. */
@ApiTags('ai')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('ai')
export class AiController {
  constructor(private service: AiService) {}

  @Post('routine')
  rutina(@CurrentUser() u: AuthenticatedUser, @Body() dto: GenerarRutinaDto) {
    return this.service.generarRutina(u.userId, dto);
  }

  @Get('routines')
  rutinas(@CurrentUser() u: AuthenticatedUser) {
    return this.service.listarRutinas(u.userId);
  }

  @Post('nutrition')
  alimentacion(@CurrentUser() u: AuthenticatedUser, @Body() dto: GenerarAlimentacionDto) {
    return this.service.generarAlimentacion(u.userId, dto);
  }

  @Get('nutrition')
  historialAlimentacion(@CurrentUser() u: AuthenticatedUser) {
    return this.service.listarAlimentacion(u.userId);
  }

  @Post('chat')
  chat(@CurrentUser() u: AuthenticatedUser, @Body() dto: ChatDto) {
    return this.service.chat(u.userId, dto);
  }
}
