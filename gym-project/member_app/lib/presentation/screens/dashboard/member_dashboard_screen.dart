import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';
import '../../../data/member_models.dart';
import '../../../providers/member_providers.dart';
import '../../widgets/plan_card.dart';

class MemberDashboardScreen extends ConsumerWidget {
  const MemberDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(memberDashboardProvider);
    final contacto = textoContacto(ref.watch(gymSettingsProvider).valueOrNull);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(memberDashboardProvider.future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          ...dashboard.when<List<Widget>>(
            loading: () => const [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (e, _) => [
              _ErrorCard(
                mensaje: e is ApiException
                    ? e.message
                    : 'No se pudo cargar tu resumen',
                onReintentar: () => ref.invalidate(memberDashboardProvider),
              ),
            ],
            data: (d) => _contenido(context, d, contacto),
          ),
        ],
      ),
    );
  }

  List<Widget> _contenido(
      BuildContext context, MemberDashboard d, String? contacto) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: AppColors.textMuted);

    final activos =
        d.planes.where((p) => p.plan.estado == EstadoPlan.activo).toList();
    final porVencer =
        d.planes.where((p) => p.plan.estado == EstadoPlan.porVencer).toList();
    final vencidos = d.planes
        .where((p) =>
            p.plan.estado == EstadoPlan.vencido ||
            p.plan.estado == EstadoPlan.agotado)
        .toList();

    final primerNombre = d.nombres.trim().split(' ').first;

    return [
      Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.ember.withValues(alpha: 0.12),
            backgroundImage: d.foto != null ? NetworkImage(d.foto!) : null,
            child: d.foto == null
                ? Text(
                    primerNombre.isNotEmpty
                        ? primerNombre[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: AppColors.ember,
                        fontWeight: FontWeight.w700,
                        fontSize: 20),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hola, $primerNombre', style: text.headlineSmall),
                Text('Este es tu resumen de hoy', style: muted),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      if (porVencer.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.estadoPorVencer.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications_active_rounded,
                  color: AppColors.estadoPorVencer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  porVencer.length == 1
                      ? 'Tienes un plan por vencer. Renueva a tiempo para no perder tu acceso.'
                      : 'Tienes ${porVencer.length} planes por vencer. Renueva a tiempo para no perder tu acceso.',
                ),
              ),
            ],
          ),
        ),
      if (d.planes.isEmpty)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aún no tienes un plan', style: text.titleMedium),
                const SizedBox(height: 6),
                Text(
                  contacto ?? 'Consulta en recepción para adquirir tu plan.',
                  style: muted,
                ),
              ],
            ),
          ),
        ),
      ..._seccion(context, 'Plan activo', activos, contacto),
      ..._seccion(context, 'Próximos a vencer', porVencer, contacto),
      ..._seccion(context, 'Vencidos', vencidos, contacto),
      const SizedBox(height: 8),
      Text('Mis medidas', style: text.titleMedium),
      const SizedBox(height: 10),
      if (d.pesoActual == null)
        Card(
          child: ListTile(
            leading: const Icon(Icons.monitor_weight_rounded,
                color: AppColors.ember),
            title: const Text('Registra tu peso y estatura'),
            subtitle: const Text('Así podrás ver tu evolución'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.go('/maintenance'),
          ),
        )
      else
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                label: 'Peso actual',
                value: '${d.pesoActual!.toStringAsFixed(1)} kg',
                icon: Icons.monitor_weight_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniStat(
                label: 'Estatura',
                value: d.estaturaActual != null
                    ? '${d.estaturaActual!.toStringAsFixed(2)} m'
                    : '—',
                icon: Icons.height_rounded,
              ),
            ),
          ],
        ),
      const SizedBox(height: 24),
      Text('Recomendado para hoy', style: text.titleMedium),
      const SizedBox(height: 10),
      Card(
        child: ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0x1FE8542A),
            child: Icon(Icons.fitness_center_rounded, color: AppColors.ember),
          ),
          title: const Text('Rutina del día'),
          subtitle: Text(d.tieneRutinaHoy
              ? 'Ya tienes una rutina generada para hoy'
              : 'La generarás con el asistente de IA (próximamente)'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.go('/ai-chat'),
        ),
      ),
      Card(
        child: ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0x1F1F7A4D),
            child: Icon(Icons.restaurant_rounded,
                color: AppColors.estadoActivo),
          ),
          title: const Text('Alimentación sugerida'),
          subtitle: Text(d.tieneAlimentacionHoy
              ? 'Ya tienes una recomendación para hoy'
              : 'Disponible con el asistente de IA (próximamente)'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.go('/ai-chat'),
        ),
      ),
    ];
  }

  List<Widget> _seccion(BuildContext context, String titulo,
      List<PlanDetalle> planes, String? contacto) {
    if (planes.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(titulo, style: Theme.of(context).textTheme.titleMedium),
      ),
      for (final p in planes) PlanCard(detalle: p, contacto: contacto),
    ];
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _MiniStat(
      {required this.label, required this.value, required this.icon});

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

class _ErrorCard extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;
  const _ErrorCard({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
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
