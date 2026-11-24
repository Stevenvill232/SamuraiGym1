export const DIA_MS = 24 * 60 * 60 * 1000;

export type EstadoPlanStr = 'ACTIVO' | 'POR_VENCER' | 'VENCIDO' | 'AGOTADO';

/**
 * Estado real de un plan en este momento, derivado de sus fechas y días
 * usados. Lo comparten Planes y Dashboard para que ambos digan lo mismo.
 */
export function calcularEstadoPlan(plan: {
  fechaVencimiento: Date;
  diasTotales: number | null;
  diasUtilizados: number;
}): EstadoPlanStr {
  if (plan.diasTotales != null && plan.diasUtilizados >= plan.diasTotales) {
    return 'AGOTADO';
  }
  const diasParaVencer = Math.ceil(
    (plan.fechaVencimiento.getTime() - Date.now()) / DIA_MS,
  );
  if (diasParaVencer < 0) return 'VENCIDO';
  if (diasParaVencer <= 2) return 'POR_VENCER';
  return 'ACTIVO';
}
