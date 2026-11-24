import { Controller, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { NotificationsService } from './notifications.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import {
  CurrentUser,
  AuthenticatedUser,
} from '../common/decorators/current-user.decorator';

/** Los endpoints "me" operan SIEMPRE sobre el usuario del token. */
@ApiTags('notifications')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('notifications')
export class NotificationsController {
  constructor(private service: NotificationsService) {}

  @Get('me')
  listar(@CurrentUser() user: AuthenticatedUser) {
    return this.service.listar(user.userId);
  }

  @Get('me/unread-count')
  noLeidas(@CurrentUser() user: AuthenticatedUser) {
    return this.service.noLeidas(user.userId);
  }

  // La app del teléfono lo consulta para mostrar notificaciones del sistema.
  @Post('me/claim')
  reclamar(@CurrentUser() user: AuthenticatedUser) {
    return this.service.reclamar(user.userId);
  }

  @Patch('me/read-all')
  marcarTodas(@CurrentUser() user: AuthenticatedUser) {
    return this.service.marcarTodas(user.userId);
  }

  @Patch(':id/read')
  marcarLeida(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.service.marcarLeida(user.userId, id);
  }

  // Para probar sin esperar a la hora siguiente (Configuración > Gimnasio).
  @Roles('ADMINISTRADOR')
  @Post('run-job')
  ejecutar() {
    return this.service.generarAvisos();
  }
}
