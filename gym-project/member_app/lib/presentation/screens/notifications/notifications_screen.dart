import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import '../../../data/member_models.dart';
import '../../../providers/member_providers.dart';

IconData _icono(String tipo) => switch (tipo) {
      'VENCIMIENTO_PLAN' => Icons.event_busy_rounded,
      'TIQUETERA' => Icons.confirmation_number_rounded,
      'PAGO' => Icons.payments_rounded,
      _ => Icons.notifications_rounded,
    };

Color _color(String tipo) => switch (tipo) {
      'VENCIMIENTO_PLAN' => AppColors.estadoPorVencer,
      'TIQUETERA' => AppColors.ember,
      'PAGO' => AppColors.estadoActivo,
      _ => AppColors.textMuted,
    };

String _cuando(DateTime f) {
  final l = f.toLocal();
  final h = DateTime.now();
  final hora =
      '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  final hoy = l.year == h.year && l.month == h.month && l.day == h.day;
  return hoy ? 'Hoy · $hora' : '${FormatoFecha.diaMesLargo(f)} · $hora';
}

/// Historial de avisos del miembro: vencimientos, pagos y tiquetera.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  void _refrescar(WidgetRef ref) {
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadCountProvider);
  }

  Future<void> _marcar(WidgetRef ref, Notificacion n) async {
    if (n.leida) return;
    try {
      await ref.read(memberRepositoryProvider).marcarNotificacionLeida(n.id);
    } on ApiException catch (_) {
      // Si falla, simplemente se verá igual que antes.
    }
    _refrescar(ref);
  }

  Future<void> _marcarTodas(WidgetRef ref) async {
    try {
      await ref.read(memberRepositoryProvider).marcarTodasLeidas();
    } on ApiException catch (_) {}
    _refrescar(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    final hayNoLeidas = async.valueOrNull?.any((n) => !n.leida) ?? false;
    final muted = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(color: AppColors.textMuted);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (hayNoLeidas)
            TextButton(
              onPressed: () => _marcarTodas(ref),
              child: const Text('Marcar todas'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () {
          ref.invalidate(unreadCountProvider);
          return ref.refresh(notificationsProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            ...async.when<List<Widget>>(
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
                              : 'No se pudieron cargar tus notificaciones',
                          style:
                              const TextStyle(color: AppColors.estadoVencido),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => ref.invalidate(notificationsProvider),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 80),
                      child: Column(
                        children: [
                          const Icon(Icons.notifications_off_outlined,
                              size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text('Aún no tienes notificaciones', style: muted),
                        ],
                      ),
                    ),
                  ];
                }
                return [
                  for (final n in lista)
                    Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      color: n.leida
                          ? null
                          : AppColors.ember.withValues(alpha: 0.05),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _marcar(ref, n),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    _color(n.tipo).withValues(alpha: 0.12),
                                child: Icon(_icono(n.tipo),
                                    color: _color(n.tipo), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      n.titulo,
                                      style: TextStyle(
                                        fontWeight: n.leida
                                            ? FontWeight.w500
                                            : FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(n.mensaje),
                                    const SizedBox(height: 6),
                                    Text(
                                      _cuando(n.fecha),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              if (!n.leida)
                                const Padding(
                                  padding: EdgeInsets.only(left: 8, top: 4),
                                  child: Icon(Icons.circle,
                                      size: 10, color: AppColors.ember),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }
}
