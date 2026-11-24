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
  final List<HorarioInfo> horarios; // un plan de deporte puede tener varios
  final List<DateTime> usos; // del más antiguo al más reciente

  const PlanDetalle(
      {required this.plan, this.horarios = const [], this.usos = const []});

  factory PlanDetalle.fromJson(Map<String, dynamic> j) {
    final u = j['usosTiquetera'];
    final hs = j['horarios'];
    final horarios = <HorarioInfo>[
      if (hs is List)
        for (final h in hs)
          if (h is Map) HorarioInfo.fromJson(Map<String, dynamic>.from(h)),
    ];
    // Planes anteriores con un único horario.
    if (horarios.isEmpty && j['horario'] is Map) {
      horarios.add(HorarioInfo.fromJson(
          Map<String, dynamic>.from(j['horario'] as Map)));
    }
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
      horarios: horarios,
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

// ---------------------------------------------------------------------- //
// Notificaciones
// ---------------------------------------------------------------------- //

class Notificacion {
  final String id;
  final String titulo;
  final String mensaje;
  final String tipo; // VENCIMIENTO_PLAN | TIQUETERA | PAGO | GENERAL
  final bool leida;
  final DateTime fecha;

  const Notificacion({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    required this.leida,
    required this.fecha,
  });

  factory Notificacion.fromJson(Map<String, dynamic> j) => Notificacion(
        id: j['id'] as String,
        titulo: (j['titulo'] as String?) ?? '',
        mensaje: (j['mensaje'] as String?) ?? '',
        tipo: (j['tipo'] as String?) ?? 'GENERAL',
        leida: (j['leida'] as bool?) ?? false,
        fecha: DateTime.parse(j['fechaEnvio'] as String),
      );
}

// ---------------------------------------------------------------------- //
// Asistente de IA
// ---------------------------------------------------------------------- //

class EjercicioIA {
  final String nombre;
  final int? series;
  final String repeticiones;
  final String descanso;
  final String? notas;

  const EjercicioIA({
    required this.nombre,
    this.series,
    this.repeticiones = '',
    this.descanso = '',
    this.notas,
  });

  factory EjercicioIA.fromJson(Map<String, dynamic> j) => EjercicioIA(
        nombre: (j['nombre'] as String?) ?? '',
        series: (j['series'] as num?)?.toInt(),
        repeticiones: (j['repeticiones'] ?? '').toString(),
        descanso: (j['descanso'] ?? '').toString(),
        notas: j['notas'] as String?,
      );
}

class RutinaIA {
  final String id;
  final DateTime fecha;
  final String? intensidad;
  final String titulo;
  final int? duracionMin;
  final List<String> calentamiento;
  final List<EjercicioIA> ejercicios;
  final List<String> enfriamiento;
  final List<String> recomendaciones;

  const RutinaIA({
    required this.id,
    required this.fecha,
    required this.titulo,
    required this.ejercicios,
    this.intensidad,
    this.duracionMin,
    this.calentamiento = const [],
    this.enfriamiento = const [],
    this.recomendaciones = const [],
  });

  factory RutinaIA.fromJson(Map<String, dynamic> j) {
    final c = Map<String, dynamic>.from(j['contenido'] as Map);
    return RutinaIA(
      id: j['id'] as String,
      fecha: DateTime.parse(j['fecha'] as String),
      intensidad: j['intensidad'] as String?,
      titulo: (c['titulo'] as String?) ?? 'Rutina',
      duracionMin: (c['duracionMin'] as num?)?.toInt(),
      calentamiento: _aLista(c['calentamiento']),
      ejercicios: [
        for (final e in (c['ejercicios'] as List? ?? []))
          if (e is Map) EjercicioIA.fromJson(Map<String, dynamic>.from(e)),
      ],
      enfriamiento: _aLista(c['enfriamiento']),
      recomendaciones: _aLista(c['recomendaciones']),
    );
  }
}

class AlimentoIA {
  final String nombre;
  final String porcion;
  const AlimentoIA({required this.nombre, this.porcion = ''});
}

class ComidaIA {
  final String id;
  final DateTime fecha;
  final String tipoComida; // DESAYUNO | MEDIA_MANANA | ALMUERZO | MERIENDA | CENA
  final String titulo;
  final int? caloriasAprox;
  final List<AlimentoIA> alimentos;
  final List<String> alternativas;
  final List<String> recomendaciones;

  const ComidaIA({
    required this.id,
    required this.fecha,
    required this.tipoComida,
    required this.titulo,
    required this.alimentos,
    this.caloriasAprox,
    this.alternativas = const [],
    this.recomendaciones = const [],
  });

  factory ComidaIA.fromJson(Map<String, dynamic> j) {
    final c = Map<String, dynamic>.from(j['contenido'] as Map);
    return ComidaIA(
      id: j['id'] as String,
      fecha: DateTime.parse(j['fecha'] as String),
      tipoComida: (j['tipoComida'] as String?) ?? '',
      titulo: (c['titulo'] as String?) ?? 'Sugerencia',
      caloriasAprox: (c['caloriasAprox'] as num?)?.toInt(),
      alimentos: [
        for (final a in (c['alimentos'] as List? ?? []))
          if (a is Map)
            AlimentoIA(
              nombre: (a['nombre'] ?? '').toString(),
              porcion: (a['porcion'] ?? '').toString(),
            ),
      ],
      alternativas: _aLista(c['alternativas']),
      recomendaciones: _aLista(c['recomendaciones']),
    );
  }
}
