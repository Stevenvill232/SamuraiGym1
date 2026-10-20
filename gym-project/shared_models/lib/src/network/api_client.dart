import 'package:dio/dio.dart';
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
      return res.data as Map<String, dynamic>;
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
  }) async {
    try {
      final res = await _dio.post(path, data: body);
      return res.data as Map<String, dynamic>;
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
      return res.data as Map<String, dynamic>;
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
      return ApiException.credencialesInvalidas();
    }
    if (status != null && status >= 500) {
      return ApiException.servidor();
    }

    final msg = backendMessage is List
        ? backendMessage.join('\n')
        : (backendMessage?.toString() ?? 'Ocurrió un error inesperado.');
    return ApiException(msg, statusCode: status);
  }
}
