/// Roles del sistema. Coincide 1:1 con la tabla `roles` del backend.
/// Se modela como enum en Flutter (más cómodo para lógica de UI) aunque en
/// el backend viva en una tabla, para poder agregar roles nuevos sin romper
/// el enum: cualquier valor desconocido cae en [UserRole.desconocido].
enum UserRole {
  administrador,
  miembro,
  recepcion,
  entrenador,
  contador,
  desconocido;

  static UserRole fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'ADMINISTRADOR':
        return UserRole.administrador;
      case 'MIEMBRO':
        return UserRole.miembro;
      case 'RECEPCION':
        return UserRole.recepcion;
      case 'ENTRENADOR':
        return UserRole.entrenador;
      case 'CONTADOR':
        return UserRole.contador;
      default:
        return UserRole.desconocido;
    }
  }

  String toApi() {
    switch (this) {
      case UserRole.administrador:
        return 'ADMINISTRADOR';
      case UserRole.miembro:
        return 'MIEMBRO';
      case UserRole.recepcion:
        return 'RECEPCION';
      case UserRole.entrenador:
        return 'ENTRENADOR';
      case UserRole.contador:
        return 'CONTADOR';
      case UserRole.desconocido:
        return 'DESCONOCIDO';
    }
  }
}

/// Representa tanto a un miembro del gimnasio como a un usuario de staff
/// (administrador, recepción, entrenador, contador): en el backend viven en
/// la misma tabla `usuarios`, diferenciados por [role].
class Usuario {
  final String id;
  final String cedula;
  final String nombres;
  final String apellidos;
  final DateTime? fechaNacimiento;
  final String? celular;
  final String? correo;
  final String? direccion;
  final String? foto;
  final String? sexo;
  final UserRole role;
  final bool activo;
  final int? edad; // calculada por el backend, nunca se envía al crear/editar

  const Usuario({
    required this.id,
    required this.cedula,
    required this.nombres,
    required this.apellidos,
    required this.role,
    this.fechaNacimiento,
    this.celular,
    this.correo,
    this.direccion,
    this.foto,
    this.sexo,
    this.activo = true,
    this.edad,
  });

  String get nombreCompleto => '$nombres $apellidos';

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as String,
      cedula: json['cedula'] as String,
      nombres: json['nombres'] as String,
      apellidos: json['apellidos'] as String,
      fechaNacimiento: json['fechaNacimiento'] != null
          ? DateTime.tryParse(json['fechaNacimiento'] as String)
          : null,
      celular: json['celular'] as String?,
      correo: json['correo'] as String?,
      direccion: json['direccion'] as String?,
      foto: json['foto'] as String?,
      sexo: json['sexo'] as String?,
      role: UserRole.fromApi(json['role'] as String? ?? ''),
      activo: (json['estado'] as String?) != 'INACTIVO',
      edad: json['edad'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cedula': cedula,
        'nombres': nombres,
        'apellidos': apellidos,
        if (fechaNacimiento != null)
          'fechaNacimiento': fechaNacimiento!.toIso8601String(),
        'celular': celular,
        'correo': correo,
        'direccion': direccion,
        'foto': foto,
        'sexo': sexo,
        'role': role.toApi(),
      };
}
