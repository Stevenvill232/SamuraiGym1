import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'core/router/app_router.dart';
import 'providers/auth_provider.dart';

void main() {
  runApp(const ProviderScope(child: GymAdminApp()));
}

class GymAdminApp extends ConsumerWidget {
  const GymAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final authStatus = ref.watch(authProvider).status;

    return MaterialApp.router(
      title: 'Gym Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      builder: (context, child) {
        // Mientras se valida la sesión guardada (arranque de la app) se
        // muestra un loader simple en vez de parpadear entre login/dashboard.
        if (authStatus == AuthStatus.desconocido) {
          return const Scaffold(
            backgroundColor: AppColors.graphite,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.ember),
            ),
          );
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
