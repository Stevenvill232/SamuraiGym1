import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

/// TODO(Fase 5 - Dashboard endpoint): reemplazar por GET /api/dashboard/miembro
/// (plan activo, próximos a vencer, vencidos, peso/estatura actuales,
/// rutina y alimentación recomendadas del día).
class MemberDashboardScreen extends StatelessWidget {
  const MemberDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hola, Carlos 👋',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text('Este es tu resumen de hoy',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 20),
          Card(
            color: AppColors.graphite,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Plan activo',
                            style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 4),
                        Text('Gimnasio - Mes',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(color: Colors.white)),
                        const SizedBox(height: 4),
                        const Text('Vence en 12 días',
                            style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.estadoActivo.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Activo',
                        style: TextStyle(
                            color: AppColors.estadoActivo,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                    label: 'Peso actual', value: '70 kg', icon: Icons.monitor_weight_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStat(
                    label: 'Estatura', value: '1.70 m', icon: Icons.height_rounded),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Recomendado para hoy',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0x1FE8542A),
                child: Icon(Icons.fitness_center_rounded, color: AppColors.ember),
              ),
              title: const Text('Rutina del día'),
              subtitle: const Text('Tren superior · 45 min'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {},
            ),
          ),
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0x1F1F7A4D),
                child: Icon(Icons.restaurant_rounded, color: AppColors.estadoActivo),
              ),
              title: const Text('Alimentación sugerida'),
              subtitle: const Text('Almuerzo alto en proteína'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _MiniStat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.ember, size: 20),
            const SizedBox(height: 10),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
