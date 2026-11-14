import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { DashboardService } from './dashboard.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import {
  CurrentUser,
  AuthenticatedUser,
} from '../common/decorators/current-user.decorator';

@ApiTags('dashboard')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('dashboard')
export class DashboardController {
  constructor(private service: DashboardService) {}

  @Roles('ADMINISTRADOR', 'RECEPCION', 'ENTRENADOR', 'CONTADOR')
  @Get('admin')
  adminResumen() {
    return this.service.adminResumen();
  }

  // Sin @Roles(): cualquier usuario autenticado ve SU propio resumen.
  @Get('miembro')
  miembroResumen(@CurrentUser() user: AuthenticatedUser) {
    return this.service.miembroResumen(user.userId);
  }
}
