import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';
import '../../../providers/auth_provider.dart';

class _NavItem {
  final String path;
  final IconData icon;
  final String label;
  const _NavItem(this.path, this.icon, this.label);
}

const _items = [
  _NavItem('/dashboard', Icons.grid_view_rounded, 'Dashboard'),
  _NavItem('/members', Icons.groups_rounded, 'Miembros'),
  _NavItem('/plans', Icons.card_membership_rounded, 'Planes y Pagos'),
  _NavItem('/accounting', Icons.receipt_long_rounded, 'Contabilidad'),
  _NavItem('/store', Icons.storefront_rounded, 'Tienda'),
  _NavItem('/settings', Icons.settings_rounded, 'Configuración'),
];

/// Shell con menú lateral, requerido explícitamente por el proyecto:
/// "Debe tener un menú lateral ... con los siguientes módulos: Dashboard,
/// Miembros, Planes y Pagos, Contabilidad, Tienda, Configuración".
class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  String _currentPath(BuildContext context) =>
      GoRouterState.of(context).matchedLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = _currentPath(context);

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 240,
            color: AppColors.graphite,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 24),
                    child: Row(
                      children: [
                        Icon(Icons.fitness_center_rounded,
                            color: AppColors.ember, size: 28),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Gym Admin',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ..._items.map((item) {
                    final selected = currentPath == item.path;
                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      child: Material(
                        color: selected
                            ? AppColors.ember.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => context.go(item.path),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                Icon(
                                  item.icon,
                                  size: 20,
                                  color: selected
                                      ? AppColors.ember
                                      : Colors.white70,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : Colors.white70,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => ref.read(authProvider.notifier).logout(),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Icon(Icons.logout_rounded,
                                  size: 20, color: Colors.white70),
                              SizedBox(width: 12),
                              Text('Cerrar sesión',
                                  style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
