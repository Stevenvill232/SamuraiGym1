import { Injectable, CanActivate, ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { ROLES_KEY } from '../decorators/roles.decorator';

/**
 * Debe ir SIEMPRE después de JwtAuthGuard: @UseGuards(JwtAuthGuard, RolesGuard)
 * porque depende de que `request.user` ya exista (lo llena JwtStrategy).
 *
 * Si el endpoint no tiene @Roles(...), se permite el acceso a cualquier
 * usuario autenticado (comportamiento "solo requiere login").
 */
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.getAllAndOverride<string[]>(
      ROLES_KEY,
      [context.getHandler(), context.getClass()],
    );

    if (!requiredRoles || requiredRoles.length === 0) {
      return true;
    }

    const { user } = context.switchToHttp().getRequest();
    return requiredRoles.includes(user?.role);
  }
}
