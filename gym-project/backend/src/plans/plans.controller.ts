import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { PlansService } from './plans.service';
import { CreatePlanDto, QueryPlanDto, UsarTiqueteraDto } from './dto/plan.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import {
  CurrentUser,
  AuthenticatedUser,
} from '../common/decorators/current-user.decorator';

@ApiTags('plans')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('plans')
export class PlansController {
  constructor(private service: PlansService) {}

  @Roles('ADMINISTRADOR', 'RECEPCION')
  @Post()
  create(@Body() dto: CreatePlanDto, @CurrentUser() user: AuthenticatedUser) {
    return this.service.create(dto, user.userId);
  }

  @Roles('ADMINISTRADOR', 'RECEPCION', 'ENTRENADOR')
  @Get()
  findAll(@Query() query: QueryPlanDto) {
    return this.service.findAll(query);
  }

  // IMPORTANTE: esta ruta literal debe declararse ANTES de ':id', si no
  // Nest intenta interpretar "me" como el parámetro :id.
  // Usada por la app de miembros: cada quien ve solo sus propios planes.
  @Get('me')
  findMisPlanes(@CurrentUser() user: AuthenticatedUser) {
    return this.service.findByMiembro(user.userId);
  }

  @Roles('ADMINISTRADOR', 'RECEPCION', 'ENTRENADOR')
  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.service.findOne(id);
  }

  @Roles('ADMINISTRADOR', 'RECEPCION', 'ENTRENADOR')
  @Patch(':id/usar-tiquetera')
  usarTiquetera(
    @Param('id') id: string,
    @Body() dto: UsarTiqueteraDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.service.usarTiquetera(id, user.userId, dto);
  }
}
