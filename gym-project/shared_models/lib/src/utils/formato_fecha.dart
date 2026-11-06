/// Formatos de fecha en español que NO dependen del paquete `intl`.
///
/// `DateFormat(..., 'es')` exige llamar antes a `initializeDateFormatting()`;
/// si se olvida (o se hace un hot reload, que no vuelve a ejecutar `main()`),
/// la pantalla revienta con `LocaleDataException`. Como solo necesitamos
/// "5 nov" y "5 nov 2026", es más robusto formatearlas directamente.
///
/// Además convierte a hora local: el backend entrega fechas en UTC, y sin
/// esto un plan que vence a las 8 p. m. (Colombia) se mostraría con el día
/// siguiente.
class FormatoFecha {
  FormatoFecha._();

  static const _meses = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  /// Ejemplo: "5 nov"
  static String corta(DateTime fecha) {
    final f = fecha.toLocal();
    return '${f.day} ${_meses[f.month - 1]}';
  }

  /// Ejemplo: "5 nov 2026"
  static String conAnio(DateTime fecha) {
    final f = fecha.toLocal();
    return '${f.day} ${_meses[f.month - 1]} ${f.year}';
  }
}
