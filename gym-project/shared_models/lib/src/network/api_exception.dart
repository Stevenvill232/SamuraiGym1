/// Traduce cualquier error de red/HTTP a un mensaje entendible para el
/// usuario final (regla de UX del proyecto: nunca mostrar errores técnicos).
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  factory ApiException.sinConexion() =>
      const ApiException('Sin conexión a internet. Verifica tu red e intenta de nuevo.');

  /// [detalle] (ej. "GET /profile → 500") solo se llena en modo debug, para
  /// que el desarrollador sepa qué petición falló.
  factory ApiException.servidor([String? detalle]) => ApiException(
        detalle == null
            ? 'Ocurrió un problema en el servidor. Intenta de nuevo en unos minutos.'
            : 'Ocurrió un problema en el servidor ($detalle). Revisa la consola del backend.',
        statusCode: 500,
      );

  factory ApiException.credencialesInvalidas() =>
      const ApiException('Cédula o contraseña incorrecta.', statusCode: 401);

  factory ApiException.sesionExpirada() => const ApiException(
      'Tu sesión expiró. Cierra sesión y vuelve a ingresar.',
      statusCode: 401);

  factory ApiException.sinPermiso() => const ApiException(
      'No tienes permiso para realizar esta acción.',
      statusCode: 403);

  @override
  String toString() => message;
}
