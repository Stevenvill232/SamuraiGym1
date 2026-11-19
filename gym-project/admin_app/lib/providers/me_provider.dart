import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'auth_provider.dart';

class AuthMe {
  final String userId;
  final String cedula;
  final UserRole role; // principal
  final Set<UserRole> roles; // todos (una persona puede tener varios)
  const AuthMe({
    required this.userId,
    required this.cedula,
    required this.role,
    required this.roles,
  });
}

/// Quién está logueado y con qué roles, leído del token (GET /auth/me).
/// Se vuelve a pedir solo cuando cambia el estado de autenticación.
final meProvider = FutureProvider<AuthMe?>((ref) async {
  final status = ref.watch(authProvider.select((s) => s.status));
  if (status != AuthStatus.autenticado) return null;

  final data = await ref.watch(apiClientProvider).get('/auth/me');
  final principal = UserRole.fromApi(data['role'] as String);
  final lista = data['roles'];
  final roles = lista is List
      ? lista.map((e) => UserRole.fromApi(e.toString())).toSet()
      : <UserRole>{principal};
  return AuthMe(
    userId: data['userId'] as String,
    cedula: data['cedula'] as String,
    role: principal,
    roles: roles,
  );
});
