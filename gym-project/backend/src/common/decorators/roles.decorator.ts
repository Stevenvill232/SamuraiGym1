import { SetMetadata } from '@nestjs/common';

export const ROLES_KEY = 'roles';

/**
 * Uso: @Roles('ADMINISTRADOR', 'RECEPCION')
 * Debe combinarse siempre con @UseGuards(JwtAuthGuard, RolesGuard).
 * Diseñado así (por nombre de rol) para poder agregar roles nuevos
 * (Entrenador, Contador) sin tocar este decorador ni el guard.
 */
export const Roles = (...roles: string[]) => SetMetadata(ROLES_KEY, roles);
