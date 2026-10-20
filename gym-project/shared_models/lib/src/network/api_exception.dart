/// Traduce cualquier error de red/HTTP a un mensaje entendible para el
/// usuario final (regla de UX del proyecto: nunca mostrar errores técnicos).
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  factory ApiException.sinConexion() =>
      const ApiException('Sin conexión a internet. Verifica tu red e intenta de nuevo.');

  factory ApiException.servidor() => const ApiException(
      'Ocurrió un problema en el servidor. Intenta de nuevo en unos minutos.');

  factory ApiException.credencialesInvalidas() =>
      const ApiException('Cédula o contraseña incorrecta.', statusCode: 401);

  @override
  String toString() => message;
}
