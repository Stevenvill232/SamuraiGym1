import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';
import '../../../providers/plans_provider.dart';
import '../../widgets/plans/plan_form_dialog.dart';
import '../../widgets/plans/plan_list_tile.dart';

class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key});

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  String? _miembroId;
  String? _nombreMiembro;
  bool _inicializado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inicializado) {
      _inicializado = true;
      final uri = GoRouterState.of(context).uri;
      _miembroId = uri.queryParameters['miembroId'];
      // Carga inicial (con o sin filtro por miembro).
      Future.microtask(
          () => ref.read(plansProvider.notifier).cargar(miembroId: _miembroId));
    }
  }

  Future<void> _abrirFormulario() async {
    final creado = await showDialog<bool>(
      context: context,
      builder: (_) => PlanFormDialog(
        miembroIdInicial: _miembroId,
        nombreMiembroInicial: _nombreMiembro,
      ),
    );
    if (creado == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan registrado correctamente')),
      );
    }
  }

  Future<void> _usarTiquetera(String planId) async {
    final error =
        await ref.read(plansProvider.notifier).usarTiquetera(planId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Día de tiquetera registrado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(plansProvider);

    // Si venimos filtrados por miembro y aún no tenemos su nombre (llegamos
    // por URL directa), lo tomamos del primer plan que llegue.
    if (_miembroId != null &&
        _nombreMiembro == null &&
        state.planes.isNotEmpty) {
      _nombreMiembro = state.planes.first.nombreMiembro;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormulario,
        icon: const Icon(Icons.add_card_rounded),
        label: const Text('Nuevo plan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Planes y Pagos',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text(
                        _miembroId != null
                            ? 'Mostrando planes de ${_nombreMiembro ?? "..."}'
                            : 'Gimnasio, tiqueteras y Boxeo/Karate/MMA',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                if (_miembroId != null)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _miembroId = null;
                        _nombreMiembro = null;
                      });
                      ref.read(plansProvider.notifier).cargar();
                    },
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                    label: const Text('Quitar filtro'),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(state.error!,
                    style: const TextStyle(color: AppColors.estadoVencido)),
              ),
            Expanded(
              child: state.cargando && state.planes.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.planes.isEmpty
                      ? Center(
                          child: Text(
                            'Todavía no hay planes registrados',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => ref
                              .read(plansProvider.notifier)
                              .cargar(miembroId: _miembroId),
                          child: ListView.builder(
                            itemCount: state.planes.length,
                            itemBuilder: (context, i) {
                              final item = state.planes[i];
                              return PlanListTile(
                                item: item,
                                mostrarMiembro: _miembroId == null,
                                onUsarTiquetera: () =>
                                    _usarTiquetera(item.plan.id),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
