import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import '../../../core/permissions.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/me_provider.dart';
import '../members/reset_password_dialog.dart';
import 'settings_common.dart';
import 'staff_form_dialog.dart';

final staffProvider = FutureProvider.autoDispose<List<Usuario>>((ref) async {
  final data = await ref
      .watch(apiClientProvider)
      .getList('/users', query: {'staff': 'true'});
  return data
      .map((j) => Usuario.fromJson(j as Map<String, dynamic>))
      .toList();
});

/// Gestión del personal y sus roles (solo administrador).
class PersonalTab extends ConsumerWidget {
  const PersonalTab({super.key});

  Future<void> _accion(BuildContext context, WidgetRef ref, String accion,
      Usuario u) async {
    switch (accion) {
      case 'editar':
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => StaffFormDialog(usuario: u),
        );
        if (ok == true) ref.invalidate(staffProvider);
        break;
      case 'clave':
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => ResetPasswordDialog(usuario: u),
        );
        if (ok == true && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Contraseña restablecida')));
        }
        break;
      case 'baja':
        final confirmar = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Desactivar usuario'),
            content: Text(
                '¿Desactivar a ${u.nombreCompleto}? Ya no podrá ingresar al sistema.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancelar')),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.estadoVencido),
                child: const Text('Desactivar'),
              ),
            ],
          ),
        );
        if (confirmar != true) return;
        try {
          await ref.read(apiClientProvider).delete('/users/${u.id}');
          ref.invalidate(staffProvider);
        } on ApiException catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(e.message)));
          }
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(staffProvider);
    final yo = ref.watch(meProvider).valueOrNull;

    return staff.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          e is ApiException ? e.message : 'No se pudo cargar el personal',
          style: const TextStyle(color: AppColors.estadoVencido),
        ),
      ),
      data: (lista) => TabScroll(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Cada rol ve y puede hacer solo lo que le corresponde.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textMuted),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => const StaffFormDialog(),
                  );
                  if (ok == true) ref.invalidate(staffProvider);
                },
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Nuevo personal'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SeccionCard(
            titulo: 'Qué puede hacer cada rol',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RolInfo('Administrador', 'Acceso total, incluida la configuración.'),
                _RolInfo('Recepción', 'Miembros, planes y pagos, y ventas de la tienda.'),
                _RolInfo('Entrenador', 'Consulta miembros y planes, registra días de tiquetera y gestiona horarios.'),
                _RolInfo('Contador', 'Contabilidad: ingresos, gastos y resumen financiero.'),
              ],
            ),
          ),
          SeccionCard(
            titulo: 'Personal activo',
            child: lista.isEmpty
                ? const Text('Aún no hay personal registrado',
                    style: TextStyle(color: AppColors.textMuted))
                : Column(
                    children: [
                      for (final u in lista)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.background,
                            child: Text(
                              u.nombres.isNotEmpty ? u.nombres[0] : '?',
                              style:
                                  const TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                          title: Text(
                            u.nombreCompleto +
                                (u.id == yo?.userId ? '  (tú)' : ''),
                            style:
                                const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle:
                              Text('CC ${u.cedula} · ${etiquetaRol(u.role)}'),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) => _accion(context, ref, v, u),
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                  value: 'editar', child: Text('Editar')),
                              const PopupMenuItem(
                                  value: 'clave',
                                  child: Text('Restablecer contraseña')),
                              if (u.id != yo?.userId)
                                const PopupMenuItem(
                                    value: 'baja', child: Text('Desactivar')),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _RolInfo extends StatelessWidget {
  final String rol;
  final String descripcion;
  const _RolInfo(this.rol, this.descripcion);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(rol,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(descripcion)),
        ],
      ),
    );
  }
}
