export const MIEMBRO = 'MIEMBRO';
export const ADMIN = 'ADMINISTRADOR';
export const ROLES_PERSONAL = ['ADMINISTRADOR', 'RECEPCION', 'ENTRENADOR', 'CONTADOR'];

/**
 * Una persona tiene un rol principal y, opcionalmente, roles adicionales
 * (ej. recepcionista que además es miembro del gimnasio). Esto devuelve
 * TODOS sus roles, sin repetir.
 */
export function rolesEfectivos(user: {
  role?: { nombre: string } | null;
  rolesAdicionales?: { nombre: string }[] | null;
}): string[] {
  const nombres = [
    user.role?.nombre,
    ...(user.rolesAdicionales ?? []).map((r) => r.nombre),
  ].filter((n): n is string => !!n);
  return Array.from(new Set(nombres));
}

export const esPersonal = (roles: string[]) => roles.some((r) => r !== MIEMBRO);
export const esMiembro = (roles: string[]) => roles.includes(MIEMBRO);
