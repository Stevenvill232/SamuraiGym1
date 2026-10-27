import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_models/shared_models.dart';
import '../../../providers/dashboard_provider.dart';
import '../../widgets/dashboard/kpi_card.dart';
import '../../widgets/dashboard/alerta_vencimiento_tile.dart';

final _formatoMoneda =
    NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumenAsync = ref.watch(dashboardProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(dashboardProvider.future),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dashboard', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'Resumen del gimnasio en tiempo real',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            resumenAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => _ErrorDashboard(
                mensaje: err is ApiException
                    ? err.message
                    : 'No se pudo cargar el dashboard',
                onReintentar: () => ref.invalidate(dashboardProvider),
              ),
              data: (resumen) => _ContenidoDashboard(resumen: resumen),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContenidoDashboard extends StatelessWidget {
  final DashboardResumen resumen;
  const _ContenidoDashboard({required this.resumen});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(builder: (context, constraints) {
          final columnas = constraints.maxWidth > 900 ? 4 : 2;
          return GridView.count(
            crossAxisCount: columnas,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              KpiCard(
                label: 'Miembros activos',
                value: '${resumen.miembrosActivos}',
                icon: Icons.groups_rounded,
              ),
              KpiCard(
                label: 'Ganancia del día',
                value: _formatoMoneda.format(resumen.gananciaDia),
                icon: Icons.today_rounded,
                accentColor: AppColors.estadoActivo,
              ),
              KpiCard(
                label: 'Ganancia del mes',
                value: _formatoMoneda.format(resumen.gananciaMes),
                icon: Icons.calendar_month_rounded,
                accentColor: AppColors.estadoActivo,
              ),
              KpiCard(
                label: 'Alertas activas',
                value: '${resumen.alertas.length}',
                icon: Icons.notifications_active_rounded,
                accentColor: AppColors.estadoPorVencer,
              ),
            ],
          );
        }),
        const SizedBox(height: 28),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Alertas de vencimiento',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                const Divider(),
                if (resumen.alertas.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No hay planes por vencer en los próximos días 🎉',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.textMuted),
                    ),
                  )
                else
                  for (final alerta in resumen.alertas)
                    AlertaVencimientoTile(alerta: alerta),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorDashboard extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;
  const _ErrorDashboard({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mensaje,
                style: const TextStyle(color: AppColors.estadoVencido)),
            const SizedBox(height: 12),
            OutlinedButton(
                onPressed: onReintentar, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
