import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { SchedulesService } from './schedules.service';
import {
  CreateHorarioDto,
  UpdateHorarioDto,
  QueryHorarioDto,
} from './dto/horario.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';

@ApiTags('schedules')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('schedules')
export class SchedulesController {
  constructor(private service: SchedulesService) {}

  @Roles('ADMINISTRADOR')
  @Post()
  create(@Body() dto: CreateHorarioDto) {
    return this.service.create(dto);
  }

  // Sin @Roles(): cualquier usuario autenticado puede consultar horarios
  // (el miembro necesita verlos para elegir a cuál asistir).
  @Get()
  findAll(@Query() query: QueryHorarioDto) {
    return this.service.findAll(query);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.service.findOne(id);
  }

  @Roles('ADMINISTRADOR')
  @Patch(':id')
  update(@Param('id') id: string, @Body() dto: UpdateHorarioDto) {
    return this.service.update(id, dto);
  }

  @Roles('ADMINISTRADOR')
  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.service.remove(id);
  }
}
