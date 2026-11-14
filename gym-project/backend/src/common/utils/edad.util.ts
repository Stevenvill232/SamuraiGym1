/**
 * La edad se calcula siempre a partir de la fecha de nacimiento y nunca se
 * almacena (regla del proyecto).
 */
export function calcularEdad(fechaNacimiento: Date | null | undefined): number | null {
  if (!fechaNacimiento) return null;
  const hoy = new Date();
  let edad = hoy.getFullYear() - fechaNacimiento.getFullYear();
  const mes = hoy.getMonth() - fechaNacimiento.getMonth();
  if (mes < 0 || (mes === 0 && hoy.getDate() < fechaNacimiento.getDate())) {
    edad--;
  }
  return edad;
}
