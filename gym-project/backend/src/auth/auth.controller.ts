import {
  Body,
  Controller,
  Get,
  HttpCode,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { PasswordResetService } from './password-reset.service';
import { LoginDto } from './dto/login.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { ConfirmarResetDto, SolicitarResetDto } from './dto/password-reset.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import {
  CurrentUser,
  AuthenticatedUser,
} from '../common/decorators/current-user.decorator';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(
    private authService: AuthService,
    private passwordReset: PasswordResetService,
  ) {}

  // POST /api/auth/login  { cedula, password } -> { access_token, user }
  @Post('login')
  login(@Body() dto: LoginDto) {
    return this.authService.login(dto.cedula, dto.password);
  }

  // GET /api/auth/me -> { userId, cedula, role, roles }
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

  // ---- Recuperación de contraseña del personal (públicos, sin token) ----

  @HttpCode(200)
  @Post('password-reset/request')
  solicitarReset(@Body() dto: SolicitarResetDto) {
    return this.passwordReset.solicitar(dto.cedula);
  }

  @HttpCode(200)
  @Post('password-reset/confirm')
  confirmarReset(@Body() dto: ConfirmarResetDto) {
    return this.passwordReset.confirmar(dto.cedula, dto.codigo, dto.nueva);
  }
}
