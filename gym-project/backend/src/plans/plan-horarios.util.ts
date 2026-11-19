const ORDEN_DIAS = [
  'LUNES',
  'MARTES',
  'MIERCOLES',
  'JUEVES',
  'VIERNES',
  'SABADO',
  'DOMINGO',
];

/** Lo que hay que incluir al leer un plan para traer todos sus horarios. */
export const INCLUDE_HORARIOS = {
  horario: true, // OBSOLETO (planes anteriores con un solo horario)
  horarios: { include: { horario: true } },
};

export function ordenarHorarios(lista: any[]): any[] {
  return [...lista].sort(
    (a, b) =>
      ORDEN_DIAS.indexOf(a.dia) - ORDEN_DIAS.indexOf(b.dia) ||
      String(a.horaInicio).localeCompare(String(b.horaInicio)),
  );
}

/**
 * Convierte la relación (PlanHorario -> Horario) en una lista simple
 * `horarios: [{dia, horaInicio, horaFin...}]`, ordenada por día y hora. Si el
 * plan es anterior a esta mejora y solo tiene el horario único antiguo, se
 * devuelve ese como lista de uno.
 */
export function aplanarHorarios(plan: any) {
  const deRelacion = (plan.horarios ?? [])
    .map((ph: any) => ph.horario)
    .filter(Boolean);
  const lista =
    deRelacion.length > 0 ? deRelacion : plan.horario ? [plan.horario] : [];
  return { ...plan, horarios: ordenarHorarios(lista) };
}
