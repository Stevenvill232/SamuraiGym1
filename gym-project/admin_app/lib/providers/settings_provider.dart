import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'auth_provider.dart';

class SettingsState {
  final AppSettings settings;
  final bool cargado; // true cuando ya llegó al menos una vez del servidor
  final bool cargando;
  final String? error;

  const SettingsState({
    this.settings = AppSettings.defaults,
    this.cargado = false,
    this.cargando = false,
    this.error,
  });

  SettingsState copyWith({
    AppSettings? settings,
    bool? cargado,
    bool? cargando,
    String? error,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      cargado: cargado ?? this.cargado,
      cargando: cargando ?? this.cargando,
      error: error,
    );
  }
}

/// Configuración del gimnasio. Mientras no cargue, los formularios usan los
/// valores por defecto (idénticos a los del backend), así nunca quedan vacíos.
class SettingsNotifier extends StateNotifier<SettingsState> {
  final ApiClient _api;
  SettingsNotifier(this._api) : super(const SettingsState()) {
    cargar();
  }

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, error: null);
    try {
      final data = await _api.get('/settings');
      state = state.copyWith(
        settings: AppSettings.fromJson(data),
        cargado: true,
        cargando: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(cargando: false, error: e.message);
    }
  }

  /// Guarda varios ajustes y recarga UNA sola vez al final.
  /// Devuelve null si todo salió bien o el mensaje de error.
  Future<String?> guardarVarias(Map<String, dynamic> cambios) async {
    try {
      for (final e in cambios.entries) {
        await _api.put('/settings/${e.key}', body: {'valor': e.value});
      }
      await cargar();
      return null;
    } on ApiException catch (e) {
      await cargar();
      return e.message;
    }
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref.watch(apiClientProvider));
});
