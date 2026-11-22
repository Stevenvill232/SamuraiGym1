import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_exception.dart';

const _tokenKey = 'auth_token';

/// Cliente HTTP único, compartido por ambas apps (admin y miembro).
///
/// Responsabilidades:
/// - Adjuntar el JWT guardado en almacenamiento seguro en cada petición.
/// - Traducir errores de Dio a [ApiException] con mensajes amigables.
/// - Centralizar la baseUrl para que cambiar de entorno (dev/prod) sea un
///   solo lugar de configuración.
class ApiClient {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  ApiClient({required String baseUrl, FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        )) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: _tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  Future<void> guardarToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> leerToken() => _storage.read(key: _tokenKey);

  Future<void> limpiarToken() => _storage.delete(key: _tokenKey);

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await _dio.get(path, queryParameters: query);
      return _asMap(res.data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<List<dynamic>> getList(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await _dio.get(path, queryParameters: query);
      return res.data as List<dynamic>;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    Duration? timeout, // para llamadas lentas (ej. generar con IA)
  }) async {
    try {
      final res = await _dio.post(
        path,
        data: body,
        options: timeout == null
            ? null
            : Options(receiveTimeout: timeout, sendTimeout: timeout),
      );
      return _asMap(res.data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final res = await _dio.patch(path, data: body);
      return _asMap(res.data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final res = await _dio.put(path, data: body);
      return _asMap(res.data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> delete(String path) async {
    try {
      await _dio.delete(path);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// No toda respuesta es un objeto: algunas (ej. crear varios horarios)
  /// devuelven una lista. Antes eso lanzaba un error de tipo DESPUÉS de que
  /// el servidor ya había guardado, dejando el diálogo cargando para siempre.
  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data == null || (data is String && data.isEmpty)) {
      return <String, dynamic>{};
    }
    return <String, dynamic>{'data': data};
  }

  ApiException _mapError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return ApiException.sinConexion();
    }

    final status = e.response?.statusCode;
    final data = e.response?.data;
    final backendMessage =
        (data is Map && data['message'] != null) ? data['message'] : null;

    if (status == 401) {
      // Solo el login con datos incorrectos es "credenciales inválidas";
      // un 401 en cualquier otra llamada significa que el token venció.
      final esLogin = e.requestOptions.path.contains('/auth/login');
      return esLogin
          ? ApiException.credencialesInvalidas()
          : ApiException.sesionExpirada();
    }
    if (status == 403) {
      return ApiException.sinPermiso();
    }
    if (status != null && status >= 500) {
      // 503 = el servidor sabe qué pasó y trae un mensaje para el usuario
      // (ej. "no se pudo enviar el correo").
      if (status == 503 && backendMessage != null) {
        return ApiException(backendMessage.toString(), statusCode: 503);
      }
      final detalle = kDebugMode
          ? '${e.requestOptions.method} ${e.requestOptions.path} → $status'
          : null;
      return ApiException.servidor(detalle);
    }

    final msg = backendMessage is List
        ? backendMessage.join('\n')
        : (backendMessage?.toString() ?? 'Ocurrió un error inesperado.');
    return ApiException(msg, statusCode: status);
  }
}
