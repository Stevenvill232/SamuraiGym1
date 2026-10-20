import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

/// URL base del backend. En desarrollo, la app admin corre en el mismo
/// computador que el backend -> localhost funciona. Si pruebas en otra
/// máquina de la red, cambia esto por la IP de tu servidor (ej. 192.168.x.x).
const String kApiBaseUrl = 'http://localhost:3000/api';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: kApiBaseUrl);
});

enum AuthStatus { desconocido, autenticado, noAutenticado }

class AuthState {
  final AuthStatus status;
  final Usuario? usuario;
  final bool cargando;
  final String? error;

  const AuthState({
    this.status = AuthStatus.desconocido,
    this.usuario,
    this.cargando = false,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    Usuario? usuario,
    bool? cargando,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      usuario: usuario ?? this.usuario,
      cargando: cargando ?? this.cargando,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _api;

  AuthNotifier(this._api) : super(const AuthState()) {
    intentarSesionGuardada();
  }

  /// Se ejecuta al abrir la app: si hay un token guardado, valida contra
  /// /auth/me. Solo ADMINISTRADOR, RECEPCION, ENTRENADOR o CONTADOR pueden
  /// entrar a esta app (un MIEMBRO que intente entrar aquí queda bloqueado:
  /// regla de negocio "el miembro no puede acceder a funcionalidades
  /// administrativas").
  Future<void> intentarSesionGuardada() async {
    final token = await _api.leerToken();
    if (token == null) {
      state = state.copyWith(status: AuthStatus.noAutenticado);
      return;
    }
    try {
      final data = await _api.get('/auth/me');
      if (data['role'] == 'MIEMBRO') {
        await _api.limpiarToken();
        state = state.copyWith(
          status: AuthStatus.noAutenticado,
          error: 'Esta aplicación es solo para personal del gimnasio.',
        );
        return;
      }
      // /auth/me devuelve el payload del JWT (userId, cedula, role), no el
      // Usuario completo -> se pide el detalle o se reconstruye mínimo.
      state = state.copyWith(status: AuthStatus.autenticado);
    } catch (_) {
      await _api.limpiarToken();
      state = state.copyWith(status: AuthStatus.noAutenticado);
    }
  }

  Future<bool> login(String cedula, String password) async {
    state = state.copyWith(cargando: true, error: null);
    try {
      final data = await _api.post('/auth/login', body: {
        'cedula': cedula,
        'password': password,
      });

      final role = data['user']['role'] as String;
      if (role == 'MIEMBRO') {
        state = state.copyWith(
          cargando: false,
          error: 'Esta aplicación es solo para personal del gimnasio.',
        );
        return false;
      }

      await _api.guardarToken(data['access_token'] as String);
      state = state.copyWith(
        status: AuthStatus.autenticado,
        usuario: Usuario.fromJson(data['user'] as Map<String, dynamic>),
        cargando: false,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(cargando: false, error: e.message);
      return false;
    }
  }

  Future<void> logout() async {
    await _api.limpiarToken();
    state = const AuthState(status: AuthStatus.noAutenticado);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(apiClientProvider));
});
