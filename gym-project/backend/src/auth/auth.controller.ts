import { Body, Controller, Get, Patch, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import {
  CurrentUser,
  AuthenticatedUser,
} from '../common/decorators/current-user.decorator';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  // POST /api/auth/login  { cedula, password } -> { access_token, user }
  @Post('login')
  login(@Body() dto: LoginDto) {
    return this.authService.login(dto.cedula, dto.password);
  }

  // GET /api/auth/me  (requiere Bearer token) -> datos del usuario logueado
  // Útil para que Flutter valide la sesión guardada al abrir la app.
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Get('me')
  me(@CurrentUser() user: AuthenticatedUser) {
    return user;
  }

  // PATCH /api/auth/password { actual, nueva } — cualquier usuario logueado.
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Patch('password')
  cambiarPassword(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: ChangePasswordDto,
  ) {
    return this.authService.cambiarPassword(user.userId, dto.actual, dto.nueva);
  }
}
