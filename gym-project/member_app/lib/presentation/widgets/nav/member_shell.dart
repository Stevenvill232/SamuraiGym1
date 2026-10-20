import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';

class _NavItem {
  final String path;
  final IconData icon;
  final String label;
  const _NavItem(this.path, this.icon, this.label);
}

const _items = [
  _NavItem('/dashboard', Icons.grid_view_rounded, 'Inicio'),
  _NavItem('/plan-line', Icons.timeline_rounded, 'Mi plan'),
  _NavItem('/ai-chat', Icons.smart_toy_rounded, 'Asistente IA'),
  _NavItem('/maintenance', Icons.monitor_weight_rounded, 'Progreso'),
  _NavItem('/profile', Icons.person_rounded, 'Perfil'),
];

/// Shell con barra de navegación inferior: Dashboard, Línea de Plan, Chat
/// IA, Mantenimiento (datos físicos) y Perfil — los 5 módulos principales
/// de la app de miembros descritos en el proyecto.
class MemberShell extends StatelessWidget {
  final Widget child;
  const MemberShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _items.indexWhere((i) => i.path == location);
    return index == -1 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          navigationBarTheme: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? Colors.white : Colors.white70,
              );
            }),
          ),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) => context.go(_items[index].path),
          backgroundColor: AppColors.graphite,
          indicatorColor: AppColors.ember.withValues(alpha: 0.2),
          destinations: _items
              .map((item) => NavigationDestination(
                    icon: Icon(item.icon, color: Colors.white70),
                    selectedIcon: Icon(item.icon, color: AppColors.ember),
                    label: item.label,
                  ))
              .toList(),
        ),
      ),
    );
  }
}
