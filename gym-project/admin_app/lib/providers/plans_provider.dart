import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'auth_provider.dart';

/// Extiende el [Plan] de shared_models con los datos del miembro que trae
/// incluido el backend (el modelo compartido no los tiene porque la app de
/// miembros no los necesita: un miembro ya sabe quién es).
String _etiquetaDiaCorta(String d) => switch (d) {
      'LUNES' => 'Lun',
      'MARTES' => 'Mar',
      'MIERCOLES' => 'Mié',
      'JUEVES' => 'Jue',
      'VIERNES' => 'Vie',
      'SABADO' => 'Sáb',
      'DOMINGO' => 'Dom',
      _ => d,
    };

/// ["Lun 17:00-18:00", "Mié 17:00-18:00"] a partir de la lista `horarios`
/// que entrega el backend (ya ordenada por día y hora).
List<String> _horariosDe(dynamic v) {
  if (v is! List) return const [];
  return [
    for (final h in v)
      if (h is Map)
        '${_etiquetaDiaCorta(h['dia'].toString())} ${h['horaInicio']}-${h['horaFin']}',
  ];
}

class PlanConMiembro {
  final Plan plan;
  final String nombreMiembro;
  final String cedulaMiembro;
  final String? fotoMiembro;
  final List<String> horarios;

  const PlanConMiembro({
    required this.plan,
    required this.nombreMiembro,
    required this.cedulaMiembro,
    this.fotoMiembro,
    this.horarios = const [],
  });

  factory PlanConMiembro.fromJson(Map<String, dynamic> json) {
    final miembro = json['miembro'] as Map<String, dynamic>?;
    return PlanConMiembro(
      plan: Plan.fromJson(json),
      nombreMiembro: miembro != null
          ? '${miembro['nombres']} ${miembro['apellidos']}'
          : 'Miembro',
      cedulaMiembro: miembro?['cedula'] as String? ?? '',
      fotoMiembro: miembro?['foto'] as String?,
      horarios: _horariosDe(json['horarios']),
    );
  }
}

class PlansState {
  final List<PlanConMiembro> planes;
  final bool cargando;
  final String? error;
  final String? miembroIdFiltro;

  const PlansState({
    this.planes = const [],
    this.cargando = false,
    this.error,
    this.miembroIdFiltro,
  });

  PlansState copyWith({
    List<PlanConMiembro>? planes,
    bool? cargando,
    String? error,
    String? miembroIdFiltro,
  }) {
    return PlansState(
      planes: planes ?? this.planes,
      cargando: cargando ?? this.cargando,
      error: error,
      miembroIdFiltro: miembroIdFiltro ?? this.miembroIdFiltro,
    );
  }
}

class PlansNotifier extends StateNotifier<PlansState> {
  final ApiClient _api;
  PlansNotifier(this._api) : super(const PlansState());

  Future<void> cargar({String? miembroId}) async {
    state = state.copyWith(cargando: true, error: null, miembroIdFiltro: miembroId);
    try {
      final data = await _api.getList(
        '/plans',
        query: miembroId != null ? {'miembroId': miembroId} : null,
      );
      state = state.copyWith(
        planes: data.map((j) => PlanConMiembro.fromJson(j)).toList(),
        cargando: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(cargando: false, error: e.message);
    }
  }

  Future<String?> crearPlan({
    required String miembroId,
    required TipoPlan tipoPlan,
    required double precio,
    required String metodoPago,
    List<String>? horarioIds,
    String? observaciones,
  }) async {
    try {
      await _api.post('/plans', body: {
        'miembroId': miembroId,
        'tipoPlan': tipoPlan.toApi(),
        'precio': precio,
        'metodoPago': metodoPago,
        if (horarioIds != null && horarioIds.isNotEmpty)
          'horarioIds': horarioIds,
        if (observaciones != null && observaciones.isNotEmpty)
          'observaciones': observaciones,
      });
      await cargar(miembroId: state.miembroIdFiltro);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> usarTiquetera(String planId, {String? observacion}) async {
    try {
      await _api.patch('/plans/$planId/usar-tiquetera', body: {
        if (observacion != null && observacion.isNotEmpty)
          'observacion': observacion,
      });
      await cargar(miembroId: state.miembroIdFiltro);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

final plansProvider = StateNotifierProvider<PlansNotifier, PlansState>((ref) {
  return PlansNotifier(ref.watch(apiClientProvider));
});

/// Lista simple de horarios, usada por el formulario de creación de plan
/// cuando el tipo elegido es Boxeo, Karate o MMA.
final horariosProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
        (ref, deporte) async {
  final api = ref.watch(apiClientProvider);
  final data = await api.getList('/schedules', query: {'deporte': deporte});
  return data.cast<Map<String, dynamic>>();
});
