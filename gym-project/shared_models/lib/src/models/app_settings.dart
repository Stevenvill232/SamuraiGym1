import 'plan.dart';

/// Información general del gimnasio (Configuración > Gimnasio).
class InfoGimnasio {
  final String nombre;
  final String telefono;
  final String direccion;
  final String horarioAtencion;

  const InfoGimnasio({
    required this.nombre,
    this.telefono = '',
    this.direccion = '',
    this.horarioAtencion = '',
  });

  factory InfoGimnasio.fromJson(Map<String, dynamic> j) => InfoGimnasio(
        nombre: (j['nombre'] as String?) ?? 'Mi Gimnasio',
        telefono: (j['telefono'] as String?) ?? '',
        direccion: (j['direccion'] as String?) ?? '',
        horarioAtencion: (j['horarioAtencion'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'telefono': telefono,
        'direccion': direccion,
        'horarioAtencion': horarioAtencion,
      };
}

class NotificacionesConfig {
  final bool avisarDosDias;
  final bool avisarUnDia;
  final bool avisarVencido;

  const NotificacionesConfig({
    this.avisarDosDias = true,
    this.avisarUnDia = true,
    this.avisarVencido = true,
  });

  factory NotificacionesConfig.fromJson(Map<String, dynamic> j) =>
      NotificacionesConfig(
        avisarDosDias: (j['avisarDosDias'] as bool?) ?? true,
        avisarUnDia: (j['avisarUnDia'] as bool?) ?? true,
        avisarVencido: (j['avisarVencido'] as bool?) ?? true,
      );

  Map<String, dynamic> toJson() => {
        'avisarDosDias': avisarDosDias,
        'avisarUnDia': avisarUnDia,
        'avisarVencido': avisarVencido,
      };
}

/// Ajustes editables del gimnasio, tal como los entrega GET /api/settings.
/// Los valores por defecto replican los del backend, así las pantallas
/// funcionan igual mientras la configuración todavía está cargando.
class AppSettings {
  final Map<String, double> preciosPlanes;
  final double tiqueteraFactorVigencia;
  final List<String> categoriasGasto;
  final List<String> metodosPago;
  final int stockMinimoDefault;
  final InfoGimnasio info;
  final NotificacionesConfig notificaciones;

  const AppSettings({
    required this.preciosPlanes,
    required this.tiqueteraFactorVigencia,
    required this.categoriasGasto,
    required this.metodosPago,
    required this.stockMinimoDefault,
    required this.info,
    required this.notificaciones,
  });

  static const AppSettings defaults = AppSettings(
    preciosPlanes: {
      'GIMNASIO_SESION': 8000,
      'GIMNASIO_QUINCENA': 40000,
      'GIMNASIO_MES': 70000,
      'TIQUETERA_10': 60000,
      'TIQUETERA_15': 85000,
      'TIQUETERA_20': 110000,
      'TIQUETERA_30': 150000,
      'BOXEO': 80000,
      'KARATE': 80000,
      'MMA': 90000,
    },
    tiqueteraFactorVigencia: 2,
    categoriasGasto: [
      'LUZ',
      'AGUA',
      'NOMINA',
      'ARRIENDO',
      'INTERNET',
      'MANTENIMIENTO',
      'IMPLEMENTOS',
      'OTRO',
    ],
    metodosPago: [
      'EFECTIVO',
      'TRANSFERENCIA',
      'NEQUI',
      'DAVIPLATA',
      'TARJETA',
      'OTRO',
    ],
    stockMinimoDefault: 5,
    info: InfoGimnasio(nombre: 'Mi Gimnasio'),
    notificaciones: NotificacionesConfig(),
  );

  double precioDe(TipoPlan tipo) =>
      preciosPlanes[tipo.toApi()] ?? defaults.preciosPlanes[tipo.toApi()] ?? 0;

  factory AppSettings.fromJson(Map<String, dynamic> j) {
    final d = AppSettings.defaults;

    final precios = <String, double>{...d.preciosPlanes};
    final rawPrecios = j['precios_planes'];
    if (rawPrecios is Map) {
      rawPrecios.forEach((k, v) {
        if (v is num) precios[k.toString()] = v.toDouble();
      });
    }

    List<String> lista(dynamic v, List<String> def) =>
        (v is List && v.isNotEmpty) ? v.map((e) => e.toString()).toList() : def;

    final factor = j['tiquetera_factor_vigencia'];
    final stock = j['stock_minimo_default'];

    return AppSettings(
      preciosPlanes: precios,
      tiqueteraFactorVigencia:
          factor is num ? factor.toDouble() : d.tiqueteraFactorVigencia,
      categoriasGasto: lista(j['categorias_gasto'], d.categoriasGasto),
      metodosPago: lista(j['metodos_pago'], d.metodosPago),
      stockMinimoDefault: stock is num ? stock.toInt() : d.stockMinimoDefault,
      info: j['info_gimnasio'] is Map
          ? InfoGimnasio.fromJson(
              Map<String, dynamic>.from(j['info_gimnasio'] as Map))
          : d.info,
      notificaciones: j['notificaciones'] is Map
          ? NotificacionesConfig.fromJson(
              Map<String, dynamic>.from(j['notificaciones'] as Map))
          : d.notificaciones,
    );
  }
}
