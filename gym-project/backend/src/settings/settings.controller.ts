import { Body, Controller, Get, Param, Put, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { SettingsService } from './settings.service';
import { UpdateSettingDto } from './dto/update-setting.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';

@ApiTags('settings')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('settings')
export class SettingsController {
  constructor(private service: SettingsService) {}

  // Cualquier usuario autenticado puede LEER (la app de miembros muestra
  // el nombre/teléfono del gimnasio; los formularios usan los catálogos).
  @Get()
  getAll() {
    return this.service.getAll();
  }

  @Roles('ADMINISTRADOR')
  @Put(':clave')
  set(@Param('clave') clave: string, @Body() dto: UpdateSettingDto) {
    return this.service.set(clave, dto.valor);
  }
}
