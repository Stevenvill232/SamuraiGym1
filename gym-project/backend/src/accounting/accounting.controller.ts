import { Body, Controller, Get, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AccountingService } from './accounting.service';
import { CreateGastoDto, QueryMovimientosDto } from './dto/accounting.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';

@ApiTags('accounting')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('ADMINISTRADOR', 'CONTADOR')
@Controller('accounting')
export class AccountingController {
  constructor(private service: AccountingService) {}

  @Get('ingresos')
  findIngresos(@Query() query: QueryMovimientosDto) {
    return this.service.findIngresos(query);
  }

  @Get('gastos')
  findGastos(@Query() query: QueryMovimientosDto) {
    return this.service.findGastos(query);
  }

  @Post('gastos')
  createGasto(@Body() dto: CreateGastoDto) {
    return this.service.createGasto(dto);
  }

  @Get('resumen')
  resumen(@Query() query: QueryMovimientosDto) {
    return this.service.resumen(query);
  }
}
