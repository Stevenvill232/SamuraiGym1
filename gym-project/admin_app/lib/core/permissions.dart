import 'package:shared_models/shared_models.dart';

/// Qué módulos del menú ve cada rol (sección 25 del proyecto). Está alineado
/// con los @Roles() del backend: aunque alguien manipulara la app, el
/// servidor rechaza lo que no le corresponde.
///
///  - Recepción: miembros y pagos (+ ventas de tienda)
///  - Entrenador: miembros (consulta), planes (consulta/usar tiquetera) y horarios
///  - Contador: contabilidad
///  - Administrador: acceso total
const _todos = {
  UserRole.administrador,
  UserRole.recepcion,
  UserRole.entrenador,
  UserRole.contador,
};

const Map<String, Set<UserRole>> kPermisosModulo = {
  '/dashboard': _todos,
  '/members': {UserRole.administrador, UserRole.recepcion, UserRole.entrenador},
  '/plans': {UserRole.administrador, UserRole.recepcion, UserRole.entrenador},
  '/accounting': {UserRole.administrador, UserRole.contador},
  '/store': {UserRole.administrador, UserRole.recepcion},
  // Todos entran a Configuración: cada rol ve solo sus pestañas
  // (todos: "Mi cuenta"; entrenador: + "Horarios"; administrador: todo).
  '/settings': _todos,
};

bool puedeVer(String ruta, UserRole? rol) =>
    rol != null && (kPermisosModulo[ruta]?.contains(rol) ?? false);

String etiquetaRol(UserRole? rol) => switch (rol) {
      UserRole.administrador => 'Administrador',
      UserRole.recepcion => 'Recepción',
      UserRole.entrenador => 'Entrenador',
      UserRole.contador => 'Contador',
      UserRole.miembro => 'Miembro',
      _ => '',
    };
