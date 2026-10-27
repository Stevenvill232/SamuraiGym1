import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';
import '../../../providers/members_provider.dart';
import '../../widgets/members/member_form_dialog.dart';
import '../../widgets/members/member_list_tile.dart';

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _abrirFormulario({Usuario? miembro}) async {
    final guardado = await showDialog<bool>(
      context: context,
      builder: (_) => MemberFormDialog(miembro: miembro),
    );
    if (guardado == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(miembro == null
              ? 'Miembro creado correctamente'
              : 'Miembro actualizado correctamente'),
        ),
      );
    }
  }

  Future<void> _confirmarEliminar(Usuario miembro) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Desactivar miembro'),
        content: Text(
          '¿Seguro que deseas desactivar a ${miembro.nombreCompleto}? '
          'Su historial de planes y pagos se conserva.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.estadoVencido),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final error =
          await ref.read(membersProvider.notifier).eliminar(miembro.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Miembro desactivado')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(membersProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Nuevo miembro'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Miembros', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'Busca, registra y gestiona a los miembros del gimnasio',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar por cédula, nombre o celular...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(membersProvider.notifier).buscar('');
                        },
                      ),
              ),
              onSubmitted: (v) => ref.read(membersProvider.notifier).buscar(v),
            ),
            const SizedBox(height: 16),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(state.error!,
                    style: const TextStyle(color: AppColors.estadoVencido)),
              ),
            Expanded(
              child: state.cargando && state.miembros.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.miembros.isEmpty
                      ? Center(
                          child: Text(
                            'No se encontraron miembros',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () =>
                              ref.read(membersProvider.notifier).cargar(),
                          child: ListView.builder(
                            itemCount: state.miembros.length,
                            itemBuilder: (context, i) {
                              final miembro = state.miembros[i];
                              return MemberListTile(
                                miembro: miembro,
                                onEdit: () =>
                                    _abrirFormulario(miembro: miembro),
                                onDelete: () => _confirmarEliminar(miembro),
                                onVerPlanes: () => context
                                    .go('/plans?miembroId=${miembro.id}'),
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
