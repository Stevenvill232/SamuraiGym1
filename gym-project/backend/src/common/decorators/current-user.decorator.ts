import { createParamDecorator, ExecutionContext } from '@nestjs/common';

export interface AuthenticatedUser {
  userId: string;
  cedula: string;
  role: string;
}

/**
 * Uso: async miEndpoint(@CurrentUser() user: AuthenticatedUser) { ... }
 * Evita repetir `req.user` (y su casteo) en cada controller.
 */
export const CurrentUser = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): AuthenticatedUser => {
    const request = ctx.switchToHttp().getRequest();
    return request.user;
  },
);
