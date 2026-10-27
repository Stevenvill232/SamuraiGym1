import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'auth_provider.dart';

class MembersState {
  final List<Usuario> miembros;
  final bool cargando;
  final String? error;
  final String busqueda;

  const MembersState({
    this.miembros = const [],
    this.cargando = false,
    this.error,
    this.busqueda = '',
  });

  MembersState copyWith({
    List<Usuario>? miembros,
    bool? cargando,
    String? error,
    String? busqueda,
  }) {
    return MembersState(
      miembros: miembros ?? this.miembros,
      cargando: cargando ?? this.cargando,
      error: error,
      busqueda: busqueda ?? this.busqueda,
    );
  }
}

class MembersNotifier extends StateNotifier<MembersState> {
  final ApiClient _api;
  MembersNotifier(this._api) : super(const MembersState()) {
    cargar();
  }

  Future<void> cargar({String? busqueda}) async {
    state = state.copyWith(cargando: true, error: null);
    try {
      final query = <String, dynamic>{'role': 'MIEMBRO'};
      final texto = busqueda ?? state.busqueda;
      if (texto.isNotEmpty) query['search'] = texto;

      final data = await _api.getList('/users', query: query);
      state = state.copyWith(
        miembros: data.map((j) => Usuario.fromJson(j)).toList(),
        cargando: false,
        busqueda: texto,
      );
    } on ApiException catch (e) {
      state = state.copyWith(cargando: false, error: e.message);
    }
  }

  void buscar(String texto) => cargar(busqueda: texto);

  Future<String?> crear({
    required String cedula,
    required String nombres,
    required String apellidos,
    required String password,
    DateTime? fechaNacimiento,
    String? celular,
    String? correo,
    String? direccion,
    String? sexo,
  }) async {
    try {
      await _api.post('/users', body: {
        'cedula': cedula,
        'nombres': nombres,
        'apellidos': apellidos,
        'password': password,
        'role': 'MIEMBRO',
        if (fechaNacimiento != null)
          'fechaNacimiento': fechaNacimiento.toIso8601String(),
        if (celular != null && celular.isNotEmpty) 'celular': celular,
        if (correo != null && correo.isNotEmpty) 'correo': correo,
        if (direccion != null && direccion.isNotEmpty) 'direccion': direccion,
        if (sexo != null && sexo.isNotEmpty) 'sexo': sexo,
      });
      await cargar();
      return null; // sin error
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> actualizar(
    String id, {
    required String nombres,
    required String apellidos,
    DateTime? fechaNacimiento,
    String? celular,
    String? correo,
    String? direccion,
    String? sexo,
  }) async {
    try {
      await _api.patch('/users/$id', body: {
        'nombres': nombres,
        'apellidos': apellidos,
        if (fechaNacimiento != null)
          'fechaNacimiento': fechaNacimiento.toIso8601String(),
        'celular': celular,
        'correo': correo,
        'direccion': direccion,
        'sexo': sexo,
      });
      await cargar();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> eliminar(String id) async {
    try {
      await _api.delete('/users/$id');
      await cargar();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

final membersProvider =
    StateNotifierProvider<MembersNotifier, MembersState>((ref) {
  return MembersNotifier(ref.watch(apiClientProvider));
});
