import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

/// URL base del backend. En un dispositivo físico o emulador, "localhost"
/// NO apunta a tu computador: usa la IP de tu máquina en la red local
/// (ej. http://192.168.1.10:3000/api) o 10.0.2.2 para el emulador de Android.
const String kApiBaseUrl = 'http://10.0.2.2:3000/api';

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

  Future<void> intentarSesionGuardada() async {
    final token = await _api.leerToken();
    if (token == null) {
      state = state.copyWith(status: AuthStatus.noAutenticado);
      return;
    }
    try {
      await _api.get('/auth/me');
      state = state.copyWith(status: AuthStatus.autenticado);
    } catch (_) {
      await _api.limpiarToken();
      state = state.copyWith(status: AuthStatus.noAutenticado);
    }
  }

  // El miembro inicia sesión con cédula (identificador inmutable) +
  // contraseña, tal como especifica el proyecto.
  Future<bool> login(String cedula, String password) async {
    state = state.copyWith(cargando: true, error: null);
    try {
      final data = await _api.post('/auth/login', body: {
        'cedula': cedula,
        'password': password,
      });

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
