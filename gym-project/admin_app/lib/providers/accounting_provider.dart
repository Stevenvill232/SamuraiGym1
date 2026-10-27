import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'auth_provider.dart';

class Movimiento {
  final String id;
  final DateTime fecha;
  final String concepto;
  final String tipoOCategoria;
  final double valor;
  final String metodoPago;

  const Movimiento({
    required this.id,
    required this.fecha,
    required this.concepto,
    required this.tipoOCategoria,
    required this.valor,
    required this.metodoPago,
  });

  factory Movimiento.ingreso(Map<String, dynamic> j) => Movimiento(
        id: j['id'] as String,
        fecha: DateTime.parse(j['fecha'] as String),
        concepto: j['concepto'] as String,
        tipoOCategoria: j['tipo'] as String,
        valor: double.parse(j['valor'].toString()),
        metodoPago: j['metodoPago'] as String,
      );

  factory Movimiento.gasto(Map<String, dynamic> j) => Movimiento(
        id: j['id'] as String,
        fecha: DateTime.parse(j['fecha'] as String),
        concepto: j['descripcion'] as String,
        tipoOCategoria: j['categoria'] as String,
        valor: double.parse(j['valor'].toString()),
        metodoPago: j['metodoPago'] as String,
      );
}

class ResumenFinanciero {
  final double totalIngresos;
  final double totalGastos;
  final double utilidad;

  const ResumenFinanciero({
    required this.totalIngresos,
    required this.totalGastos,
    required this.utilidad,
  });

  factory ResumenFinanciero.fromJson(Map<String, dynamic> j) =>
      ResumenFinanciero(
        totalIngresos: double.parse((j['totalIngresos'] ?? 0).toString()),
        totalGastos: double.parse((j['totalGastos'] ?? 0).toString()),
        utilidad: double.parse((j['utilidad'] ?? 0).toString()),
      );
}

class AccountingState {
  final ResumenFinanciero? resumen;
  final List<Movimiento> ingresos;
  final List<Movimiento> gastos;
  final bool cargando;
  final String? error;

  const AccountingState({
    this.resumen,
    this.ingresos = const [],
    this.gastos = const [],
    this.cargando = false,
    this.error,
  });

  AccountingState copyWith({
    ResumenFinanciero? resumen,
    List<Movimiento>? ingresos,
    List<Movimiento>? gastos,
    bool? cargando,
    String? error,
  }) {
    return AccountingState(
      resumen: resumen ?? this.resumen,
      ingresos: ingresos ?? this.ingresos,
      gastos: gastos ?? this.gastos,
      cargando: cargando ?? this.cargando,
      error: error,
    );
  }
}

class AccountingNotifier extends StateNotifier<AccountingState> {
  final ApiClient _api;
  AccountingNotifier(this._api) : super(const AccountingState()) {
    cargar();
  }

  /// Por defecto trae el mes en curso, que es lo más útil para la pantalla
  /// principal de Contabilidad.
  Future<void> cargar() async {
    state = state.copyWith(cargando: true, error: null);
    try {
      final ahora = DateTime.now();
      final desde = DateTime(ahora.year, ahora.month, 1).toIso8601String();

      final results = await Future.wait([
        _api.get('/accounting/resumen', query: {'desde': desde}),
        _api.getList('/accounting/ingresos', query: {'desde': desde}),
        _api.getList('/accounting/gastos', query: {'desde': desde}),
      ]);

      state = state.copyWith(
        resumen: ResumenFinanciero.fromJson(results[0] as Map<String, dynamic>),
        ingresos: (results[1] as List)
            .map((j) => Movimiento.ingreso(j as Map<String, dynamic>))
            .toList(),
        gastos: (results[2] as List)
            .map((j) => Movimiento.gasto(j as Map<String, dynamic>))
            .toList(),
        cargando: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(cargando: false, error: e.message);
    }
  }

  Future<String?> registrarGasto({
    required String categoria,
    required String descripcion,
    required double valor,
    required String metodoPago,
    String? observacion,
  }) async {
    try {
      await _api.post('/accounting/gastos', body: {
        'categoria': categoria,
        'descripcion': descripcion,
        'valor': valor,
        'metodoPago': metodoPago,
        if (observacion != null && observacion.isNotEmpty)
          'observacion': observacion,
      });
      await cargar();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

final accountingProvider =
    StateNotifierProvider<AccountingNotifier, AccountingState>((ref) {
  return AccountingNotifier(ref.watch(apiClientProvider));
});
