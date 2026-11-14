import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import '../../../providers/me_provider.dart';
import '../../widgets/settings/catalogos_tab.dart';
import '../../widgets/settings/cuenta_tab.dart';
import '../../widgets/settings/gimnasio_tab.dart';
import '../../widgets/settings/horarios_tab.dart';
import '../../widgets/settings/personal_tab.dart';
import '../../widgets/settings/precios_tab.dart';
import '../../widgets/settings/settings_common.dart';

class _ConfigTab {
  final String titulo;
  final Widget contenido;
  const _ConfigTab(this.titulo, this.contenido);
}

/// Configuración (sección 26). Cada rol ve solo sus pestañas:
///  - Administrador: todas
///  - Entrenador: Horarios + Mi cuenta
///  - Recepción y Contador: Mi cuenta
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);

    return me.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(
        child: Text('No se pudo verificar tu rol. Cierra sesión e ingresa de nuevo.'),
      ),
      data: (m) {
        final rol = m?.role;
        final esAdmin = rol == UserRole.administrador;
        final tabs = <_ConfigTab>[
          if (esAdmin)
            _ConfigTab('Precios',
                SettingsGate(builder: (s) => PreciosTab(settings: s))),
          if (esAdmin)
            _ConfigTab('Catálogos',
                SettingsGate(builder: (s) => CatalogosTab(settings: s))),
          if (esAdmin || rol == UserRole.entrenador)
            const _ConfigTab('Horarios', HorariosTab()),
          if (esAdmin) const _ConfigTab('Personal', PersonalTab()),
          if (esAdmin)
            _ConfigTab('Gimnasio',
                SettingsGate(builder: (s) => GimnasioTab(settings: s))),
          const _ConfigTab('Mi cuenta', CuentaTab()),
        ];

        return DefaultTabController(
          length: tabs.length,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Configuración',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  'Los cambios no modifican registros históricos',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: AppColors.ember,
                  unselectedLabelColor: AppColors.textMuted,
                  indicatorColor: AppColors.ember,
                  tabs: [for (final t in tabs) Tab(text: t.titulo)],
                ),
                Expanded(
                  child: TabBarView(
                    children: [for (final t in tabs) t.contenido],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
