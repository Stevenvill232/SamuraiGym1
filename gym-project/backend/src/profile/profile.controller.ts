import { Body, Controller, Get, Patch, Put, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { ProfileService } from './profile.service';
import {
  UpdateProfileDto,
  GuardarAlimentacionDto,
  GuardarEntrenamientoDto,
} from './dto/profile.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import {
  CurrentUser,
  AuthenticatedUser,
} from '../common/decorators/current-user.decorator';

/**
 * Autoservicio del usuario logueado: SIEMPRE opera sobre su propio id (el
 * del token), nunca recibe un id por parámetro, así que un miembro no puede
 * tocar el perfil de otro.
 */
@ApiTags('profile')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('profile')
export class ProfileController {
  constructor(private service: ProfileService) {}

  @Get()
  getProfile(@CurrentUser() user: AuthenticatedUser) {
    return this.service.getProfile(user.userId);
  }

  @Patch()
  update(@CurrentUser() user: AuthenticatedUser, @Body() dto: UpdateProfileDto) {
    return this.service.updateProfile(user.userId, dto);
  }

  @Put('nutrition')
  guardarAlimentacion(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: GuardarAlimentacionDto,
  ) {
    return this.service.guardarAlimentacion(user.userId, dto);
  }

  @Put('training')
  guardarEntrenamiento(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: GuardarEntrenamientoDto,
  ) {
    return this.service.guardarEntrenamiento(user.userId, dto);
  }
}
