import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/members/members_screen.dart';
import '../../presentation/screens/plans/plans_screen.dart';
import '../../presentation/screens/accounting/accounting_screen.dart';
import '../../presentation/screens/store/store_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/widgets/nav/app_shell.dart';

/// Puentea el StateNotifierProvider de Riverpod con `Listenable`, que es lo
/// que go_router necesita para re-evaluar `redirect` cuando cambia el estado
/// de autenticación (login/logout) sin tener que reconstruir todo el router.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final vaAlLogin = state.matchedLocation == '/login';

      if (auth.status == AuthStatus.desconocido) {
        return null; // esperando a intentarSesionGuardada(); no redirigir aún
      }
      if (auth.status == AuthStatus.noAutenticado && !vaAlLogin) {
        return '/login';
      }
      if (auth.status == AuthStatus.autenticado && vaAlLogin) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/members',
            builder: (context, state) => const MembersScreen(),
          ),
          GoRoute(
            path: '/plans',
            builder: (context, state) => const PlansScreen(),
          ),
          GoRoute(
            path: '/accounting',
            builder: (context, state) => const AccountingScreen(),
          ),
          GoRoute(
            path: '/store',
            builder: (context, state) => const StoreScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
