import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import '../../../data/member_models.dart';
import '../../../providers/member_providers.dart';
import '../../widgets/plan_card.dart';

/// "Línea de Plan": todos los planes del miembro, con el detalle de cada uno
/// (fechas, días restantes, horario, días de tiquetera usados) e historial.
class PlanLineScreen extends ConsumerWidget {
  const PlanLineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planes = ref.watch(memberPlansProvider);
    final contacto = textoContacto(ref.watch(gymSettingsProvider).valueOrNull);
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: AppColors.textMuted);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(memberPlansProvider.future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text('Mi plan', style: text.headlineSmall),
          const SizedBox(height: 4),
          Text('Tu plan actual, tiquetera e historial', style: muted),
          const SizedBox(height: 20),
          ...planes.when<List<Widget>>(
            loading: () => const [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (e, _) => [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e is ApiException
                            ? e.message
                            : 'No se pudieron cargar tus planes',
                        style:
                            const TextStyle(color: AppColors.estadoVencido),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => ref.invalidate(memberPlansProvider),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            data: (lista) {
              if (lista.isEmpty) {
                return [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        contacto ??
                            'Todavía no tienes planes registrados. Consulta en recepción.',
                        style: muted,
                      ),
                    ),
                  ),
                ];
              }
              final vigentes = lista
                  .where((p) =>
                      p.plan.estado == EstadoPlan.activo ||
                      p.plan.estado == EstadoPlan.porVencer)
                  .toList();
              final historial = lista
                  .where((p) =>
                      p.plan.estado == EstadoPlan.vencido ||
                      p.plan.estado == EstadoPlan.agotado)
                  .toList();
              return [
                if (vigentes.isNotEmpty) ...[
                  Text('Vigentes', style: text.titleMedium),
                  const SizedBox(height: 10),
                  for (final p in vigentes)
                    PlanCard(detalle: p, detallado: true, contacto: contacto),
                ],
                if (historial.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Historial', style: text.titleMedium),
                  const SizedBox(height: 10),
                  for (final p in historial)
                    PlanCard(detalle: p, detallado: true, contacto: contacto),
                ],
              ];
            },
          ),
        ],
      ),
    );
  }
}
