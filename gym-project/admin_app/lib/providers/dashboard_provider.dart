import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'auth_provider.dart';
import '../presentation/widgets/dashboard/alerta_vencimiento_tile.dart';

class DashboardResumen {
  final int miembrosActivos;
  final double gananciaDia;
  final double gananciaMes;
  final List<AlertaVencimiento> alertas;

  const DashboardResumen({
    required this.miembrosActivos,
    required this.gananciaDia,
    required this.gananciaMes,
    required this.alertas,
  });

  factory DashboardResumen.fromJson(Map<String, dynamic> json) {
    final alertasJson = json['alertas'] as List<dynamic>? ?? [];
    return DashboardResumen(
      miembrosActivos: json['miembrosActivos'] as int? ?? 0,
      gananciaDia: double.parse((json['gananciaDia'] ?? 0).toString()),
      gananciaMes: double.parse((json['gananciaMes'] ?? 0).toString()),
      alertas: alertasJson.map((a) => _alertaFromJson(a)).toList(),
    );
  }

  static AlertaVencimiento _alertaFromJson(Map<String, dynamic> json) {
    final severidad = switch (json['severidad'] as String) {
      'DOS_DIAS' => SeveridadAlerta.dosDias,
      'UN_DIA' => SeveridadAlerta.unDia,
      _ => SeveridadAlerta.vencidaReciente,
    };
    return AlertaVencimiento(
      nombreMiembro: json['nombreMiembro'] as String,
      foto: json['foto'] as String?,
      tipoPlan: TipoPlan.fromApi(json['tipoPlan'] as String).etiqueta,
      fechaVencimiento: DateTime.parse(json['fechaVencimiento'] as String),
      severidad: severidad,
    );
  }
}

/// autoDispose: cada vez que se entra al Dashboard se piden cifras frescas
/// en vez de arrastrar datos viejos de una sesión anterior.
final dashboardProvider =
    FutureProvider.autoDispose<DashboardResumen>((ref) async {
  final api = ref.watch(apiClientProvider);
  final data = await api.get('/dashboard/admin');
  return DashboardResumen.fromJson(data);
});
