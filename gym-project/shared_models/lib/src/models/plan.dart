enum TipoPlan {
  gimnasioSesion,
  gimnasioQuincena,
  gimnasioMes,
  tiquetera10,
  tiquetera15,
  tiquetera20,
  tiquetera30,
  boxeo,
  karate,
  mma;

  static TipoPlan fromApi(String value) => TipoPlan.values.firstWhere(
        (t) => t.toApi() == value,
        orElse: () => TipoPlan.gimnasioSesion,
      );

  String toApi() => switch (this) {
        TipoPlan.gimnasioSesion => 'GIMNASIO_SESION',
        TipoPlan.gimnasioQuincena => 'GIMNASIO_QUINCENA',
        TipoPlan.gimnasioMes => 'GIMNASIO_MES',
        TipoPlan.tiquetera10 => 'TIQUETERA_10',
        TipoPlan.tiquetera15 => 'TIQUETERA_15',
        TipoPlan.tiquetera20 => 'TIQUETERA_20',
        TipoPlan.tiquetera30 => 'TIQUETERA_30',
        TipoPlan.boxeo => 'BOXEO',
        TipoPlan.karate => 'KARATE',
        TipoPlan.mma => 'MMA',
      };

  bool get esTiquetera => name.startsWith('tiquetera');

  String get etiqueta => switch (this) {
        TipoPlan.gimnasioSesion => 'Gimnasio - Sesión',
        TipoPlan.gimnasioQuincena => 'Gimnasio - Quincena',
        TipoPlan.gimnasioMes => 'Gimnasio - Mes',
        TipoPlan.tiquetera10 => 'Tiquetera 10 días',
        TipoPlan.tiquetera15 => 'Tiquetera 15 días',
        TipoPlan.tiquetera20 => 'Tiquetera 20 días',
        TipoPlan.tiquetera30 => 'Tiquetera 30 días',
        TipoPlan.boxeo => 'Boxeo',
        TipoPlan.karate => 'Karate',
        TipoPlan.mma => 'MMA',
      };
}

/// Refleja los 4 estados de negocio definidos en el proyecto:
/// activo / próximo a vencer / vencido / agotado (solo tiqueteras).
enum EstadoPlan {
  activo,
  porVencer,
  vencido,
  agotado;

  static EstadoPlan fromApi(String value) => switch (value) {
        'ACTIVO' => EstadoPlan.activo,
        'POR_VENCER' => EstadoPlan.porVencer,
        'VENCIDO' => EstadoPlan.vencido,
        'AGOTADO' => EstadoPlan.agotado,
        _ => EstadoPlan.activo,
      };

  String get etiqueta => switch (this) {
        EstadoPlan.activo => 'Activo',
        EstadoPlan.porVencer => 'Por vencer',
        EstadoPlan.vencido => 'Vencido',
        EstadoPlan.agotado => 'Agotado',
      };
}

class Plan {
  final String id;
  final String miembroId;
  final TipoPlan tipoPlan;
  final double precio;
  final DateTime fechaInicio;
  final DateTime fechaVencimiento;
  final int? diasTotales;
  final int diasUtilizados;
  final EstadoPlan estado;
  final String? observaciones;

  const Plan({
    required this.id,
    required this.miembroId,
    required this.tipoPlan,
    required this.precio,
    required this.fechaInicio,
    required this.fechaVencimiento,
    required this.estado,
    this.diasTotales,
    this.diasUtilizados = 0,
    this.observaciones,
  });

  int? get diasRestantes =>
      diasTotales != null ? diasTotales! - diasUtilizados : null;

  int get diasParaVencer =>
      fechaVencimiento.difference(DateTime.now()).inDays;

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id'] as String,
      miembroId: json['miembroId'] as String,
      tipoPlan: TipoPlan.fromApi(json['tipoPlan'] as String),
      precio: double.parse(json['precio'].toString()),
      fechaInicio: DateTime.parse(json['fechaInicio'] as String),
      fechaVencimiento: DateTime.parse(json['fechaVencimiento'] as String),
      diasTotales: json['diasTotales'] as int?,
      diasUtilizados: json['diasUtilizados'] as int? ?? 0,
      estado: EstadoPlan.fromApi(json['estado'] as String),
      observaciones: json['observaciones'] as String?,
    );
  }
}
