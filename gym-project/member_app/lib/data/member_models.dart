import 'package:shared_models/shared_models.dart';

double? _aDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

List<String> _aLista(dynamic v) =>
    v is List ? v.map((e) => e.toString()).toList() : <String>[];

DateTime? _aFecha(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString());

String _etiquetaDia(String d) => switch (d) {
      'LUNES' => 'Lunes',
      'MARTES' => 'Martes',
      'MIERCOLES' => 'Miércoles',
      'JUEVES' => 'Jueves',
      'VIERNES' => 'Viernes',
      'SABADO' => 'Sábado',
      'DOMINGO' => 'Domingo',
      _ => d,
    };

// ---------------------------------------------------------------------- //
// Planes
// ---------------------------------------------------------------------- //

class HorarioInfo {
  final String deporte;
  final String dia;
  final String horaInicio;
  final String horaFin;

  const HorarioInfo({
    required this.deporte,
    required this.dia,
    required this.horaInicio,
    required this.horaFin,
  });

  String get etiqueta => '${_etiquetaDia(dia)} · $horaInicio - $horaFin';

  factory HorarioInfo.fromJson(Map<String, dynamic> j) => HorarioInfo(
        deporte: (j['deporte'] as String?) ?? '',
        dia: (j['dia'] as String?) ?? '',
        horaInicio: (j['horaInicio'] as String?) ?? '',
        horaFin: (j['horaFin'] as String?) ?? '',
      );
}

/// Un plan del miembro con todo lo que la app necesita mostrar: el [Plan]
/// compartido, su horario (deportes) y los días de tiquetera ya usados.
class PlanDetalle {
  final Plan plan;
  final HorarioInfo? horario;
  final List<DateTime> usos; // del más antiguo al más reciente

  const PlanDetalle({required this.plan, this.horario, this.usos = const []});

  factory PlanDetalle.fromJson(Map<String, dynamic> j) {
    final h = j['horario'];
    final u = j['usosTiquetera'];
    final usos = <DateTime>[];
    if (u is List) {
      for (final item in u) {
        final f = _aFecha((item as Map)['fechaUso']);
        if (f != null) usos.add(f);
      }
      usos.sort();
    }
    return PlanDetalle(
      plan: Plan.fromJson(j),
      horario: h is Map
          ? HorarioInfo.fromJson(Map<String, dynamic>.from(h))
          : null,
      usos: usos,
    );
  }

  /// Días hasta el vencimiento, redondeando hacia arriba (misma regla que
  /// el backend). Negativo = ya venció.
  int get diasParaVencer {
    final minutos = plan.fechaVencimiento.difference(DateTime.now()).inMinutes;
    return (minutos / 1440).ceil();
  }

  /// Fracción del tiempo del plan que ya transcurrió (0 a 1).
  double get progresoTiempo {
    final total = plan.fechaVencimiento
        .difference(plan.fechaInicio)
        .inMilliseconds;
    if (total <= 0) return 1;
    final transcurrido =
        DateTime.now().difference(plan.fechaInicio).inMilliseconds;
    return (transcurrido / total).clamp(0.0, 1.0);
  }
}

// ---------------------------------------------------------------------- //
// Perfil
// ---------------------------------------------------------------------- //

class PerfilAlimentacion {
  final String? objetivo;
  final String? tipoDieta;
  final int? numeroComidas;
  final double? presupuesto;
  final List<String> alimentosNoConsumidos;
  final List<String> alimentosNoGustan;
  final List<String> alergias;
  final List<String> restricciones;
  final List<String> preferencias;

  const PerfilAlimentacion({
    this.objetivo,
    this.tipoDieta,
    this.numeroComidas,
    this.presupuesto,
    this.alimentosNoConsumidos = const [],
    this.alimentosNoGustan = const [],
    this.alergias = const [],
    this.restricciones = const [],
    this.preferencias = const [],
  });

  factory PerfilAlimentacion.fromJson(Map<String, dynamic> j) =>
      PerfilAlimentacion(
        objetivo: j['objetivo'] as String?,
        tipoDieta: j['tipoDieta'] as String?,
        numeroComidas: (j['numeroComidas'] as num?)?.toInt(),
        presupuesto: _aDouble(j['presupuesto']),
        alimentosNoConsumidos: _aLista(j['alimentosNoConsumidos']),
        alimentosNoGustan: _aLista(j['alimentosNoGustan']),
        alergias: _aLista(j['alergias']),
        restricciones: _aLista(j['restricciones']),
        preferencias: _aLista(j['preferencias']),
      );

  Map<String, dynamic> toJson() => {
        'objetivo': objetivo,
        'tipoDieta': tipoDieta,
        'numeroComidas': numeroComidas,
        'presupuesto': presupuesto,
        'alimentosNoConsumidos': alimentosNoConsumidos,
        'alimentosNoGustan': alimentosNoGustan,
        'alergias': alergias,
        'restricciones': restricciones,
        'preferencias': preferencias,
      };
}

class PerfilEntrenamiento {
  final String? objetivo;
  final String? nivel; // PRINCIPIANTE | INTERMEDIO | AVANZADO
  final List<String> lesiones;
  final List<String> equipamiento;
  final List<String> diasDisponibles; // LUNES..DOMINGO
  final int? minutosPorSesion;
  final List<String> preferencias;

  const PerfilEntrenamiento({
    this.objetivo,
    this.nivel,
    this.lesiones = const [],
    this.equipamiento = const [],
    this.diasDisponibles = const [],
    this.minutosPorSesion,
    this.preferencias = const [],
  });

  factory PerfilEntrenamiento.fromJson(Map<String, dynamic> j) =>
      PerfilEntrenamiento(
        objetivo: j['objetivo'] as String?,
        nivel: j['nivel'] as String?,
        lesiones: _aLista(j['lesiones']),
        equipamiento: _aLista(j['equipamiento']),
        diasDisponibles: _aLista(j['diasDisponibles']),
        minutosPorSesion: (j['minutosPorSesion'] as num?)?.toInt(),
        preferencias: _aLista(j['preferencias']),
      );

  Map<String, dynamic> toJson() => {
        'objetivo': objetivo,
        'nivel': nivel,
        'lesiones': lesiones,
        'equipamiento': equipamiento,
        'diasDisponibles': diasDisponibles,
        'minutosPorSesion': minutosPorSesion,
        'preferencias': preferencias,
      };
}

class MemberProfile {
  final String id;
  final String cedula;
  final String nombres;
  final String apellidos;
  final DateTime? fechaNacimiento;
  final int? edad;
  final String? celular;
  final String? correo;
  final String? direccion;
  final String? foto;
  final String? sexo;
  final double? pesoActual;
  final double? estaturaActual;
  final DateTime? ultimoRegistroFisico;
  final PerfilAlimentacion? alimentacion;
  final PerfilEntrenamiento? entrenamiento;

  const MemberProfile({
    required this.id,
    required this.cedula,
    required this.nombres,
    required this.apellidos,
    this.fechaNacimiento,
    this.edad,
    this.celular,
    this.correo,
    this.direccion,
    this.foto,
    this.sexo,
    this.pesoActual,
    this.estaturaActual,
    this.ultimoRegistroFisico,
    this.alimentacion,
    this.entrenamiento,
  });

  String get nombreCompleto => '$nombres $apellidos';
  String get inicial => nombres.isNotEmpty ? nombres[0].toUpperCase() : '?';

  factory MemberProfile.fromJson(Map<String, dynamic> j) => MemberProfile(
        id: j['id'] as String,
        cedula: j['cedula'] as String,
        nombres: j['nombres'] as String,
        apellidos: j['apellidos'] as String,
        fechaNacimiento: _aFecha(j['fechaNacimiento']),
        edad: (j['edad'] as num?)?.toInt(),
        celular: j['celular'] as String?,
        correo: j['correo'] as String?,
        direccion: j['direccion'] as String?,
        foto: j['foto'] as String?,
        sexo: j['sexo'] as String?,
        pesoActual: _aDouble(j['pesoActual']),
        estaturaActual: _aDouble(j['estaturaActual']),
        ultimoRegistroFisico: _aFecha(j['ultimoRegistroFisico']),
        alimentacion: j['alimentacion'] is Map
            ? PerfilAlimentacion.fromJson(
                Map<String, dynamic>.from(j['alimentacion'] as Map))
            : null,
        entrenamiento: j['entrenamiento'] is Map
            ? PerfilEntrenamiento.fromJson(
                Map<String, dynamic>.from(j['entrenamiento'] as Map))
            : null,
      );
}

// ---------------------------------------------------------------------- //
// Progreso y dashboard
// ---------------------------------------------------------------------- //

class RegistroFisico {
  final String id;
  final double peso; // kg
  final double estatura; // m
  final DateTime fecha;

  const RegistroFisico({
    required this.id,
    required this.peso,
    required this.estatura,
    required this.fecha,
  });

  factory RegistroFisico.fromJson(Map<String, dynamic> j) => RegistroFisico(
        id: j['id'] as String,
        peso: (j['peso'] as num).toDouble(),
        estatura: (j['estatura'] as num).toDouble(),
        fecha: DateTime.parse(j['fecha'] as String),
      );
}

class MemberDashboard {
  final String nombres;
  final String? foto;
  final List<PlanDetalle> planes;
  final double? pesoActual;
  final double? estaturaActual;
  final DateTime? ultimoRegistroFisico;
  final bool tieneRutinaHoy;
  final bool tieneAlimentacionHoy;

  const MemberDashboard({
    required this.nombres,
    required this.planes,
    this.foto,
    this.pesoActual,
    this.estaturaActual,
    this.ultimoRegistroFisico,
    this.tieneRutinaHoy = false,
    this.tieneAlimentacionHoy = false,
  });

  factory MemberDashboard.fromJson(Map<String, dynamic> j) {
    final u = (j['usuario'] as Map?) ?? const {};
    final planes = (j['planes'] as List? ?? [])
        .map((p) => PlanDetalle.fromJson(Map<String, dynamic>.from(p as Map)))
        .toList();
    return MemberDashboard(
      nombres: (u['nombres'] as String?) ?? '',
      foto: u['foto'] as String?,
      planes: planes,
      pesoActual: _aDouble(j['pesoActual']),
      estaturaActual: _aDouble(j['estaturaActual']),
      ultimoRegistroFisico: _aFecha(j['ultimoRegistroFisico']),
      tieneRutinaHoy: j['rutinaDelDia'] != null,
      tieneAlimentacionHoy: j['recomendacionDelDia'] != null,
    );
  }
}
