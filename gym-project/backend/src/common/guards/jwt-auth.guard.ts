import { Injectable } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

/**
 * Aplica la estrategia 'jwt' (ver auth/strategies/jwt.strategy.ts).
 * Uso: @UseGuards(JwtAuthGuard) en cualquier controller/endpoint protegido.
 */
@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {}
