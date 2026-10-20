import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';
import '../../widgets/dashboard/kpi_card.dart';
import '../../widgets/dashboard/alerta_vencimiento_tile.dart';

/// TODO(Fase 4 - Dashboard endpoint): reemplazar estos datos de ejemplo por
/// una llamada real a GET /api/dashboard/admin una vez exista ese endpoint
/// en el backend (agrega: miembrosActivos, gananciaDia, gananciaMes,
/// alertasVencimiento[]). El layout y los widgets ya están listos para
/// recibir datos reales sin cambios adicionales.
final _alertasEjemplo = [
  AlertaVencimiento(
    nombreMiembro: 'Carlos Ramírez',
    tipoPlan: 'Gimnasio - Mes',
    fechaVencimiento: DateTime.now().add(const Duration(days: 2)),
    severidad: SeveridadAlerta.dosDias,
  ),
  AlertaVencimiento(
    nombreMiembro: 'Laura Gómez',
    tipoPlan: 'Tiquetera 10 días',
    fechaVencimiento: DateTime.now().add(const Duration(days: 1)),
    severidad: SeveridadAlerta.unDia,
  ),
  AlertaVencimiento(
    nombreMiembro: 'Andrés Torres',
    tipoPlan: 'Boxeo',
    fechaVencimiento: DateTime.now().subtract(const Duration(days: 1)),
    severidad: SeveridadAlerta.vencidaReciente,
  ),
];

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
          LayoutBuilder(builder: (context, constraints) {
            final columnas = constraints.maxWidth > 900 ? 4 : 2;
            return GridView.count(
              crossAxisCount: columnas,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: const [
                KpiCard(
                  label: 'Miembros activos',
                  value: '128',
                  icon: Icons.groups_rounded,
                ),
                KpiCard(
                  label: 'Ganancia del día',
                  value: '\$ 480.000',
                  icon: Icons.today_rounded,
                  accentColor: AppColors.estadoActivo,
                ),
                KpiCard(
                  label: 'Ganancia del mes',
                  value: '\$ 9.850.000',
                  icon: Icons.calendar_month_rounded,
                  accentColor: AppColors.estadoActivo,
                ),
                KpiCard(
                  label: 'Alertas activas',
                  value: '3',
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
                  for (final alerta in _alertasEjemplo)
                    AlertaVencimientoTile(alerta: alerta),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
