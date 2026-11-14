import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'auth_provider.dart';

class AuthMe {
  final String userId;
  final String cedula;
  final UserRole role;
  const AuthMe({required this.userId, required this.cedula, required this.role});
}

/// Quién está logueado y con qué rol, leído del token (GET /auth/me). Sirve
/// también cuando la sesión se restauró al abrir la app. Se vuelve a pedir
/// solo cuando cambia el estado de autenticación (login / logout).
final meProvider = FutureProvider<AuthMe?>((ref) async {
  final status = ref.watch(authProvider.select((s) => s.status));
  if (status != AuthStatus.autenticado) return null;

  final data = await ref.watch(apiClientProvider).get('/auth/me');
  return AuthMe(
    userId: data['userId'] as String,
    cedula: data['cedula'] as String,
    role: UserRole.fromApi(data['role'] as String),
  );
});
