import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/member_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _cerrarSesion(BuildContext context, WidgetRef ref) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres cerrar tu sesión?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(profileProvider);
    final gym = ref.watch(gymSettingsProvider).valueOrNull;
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: AppColors.textMuted);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(profileProvider.future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          ...perfil.when<List<Widget>>(
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
                            : 'No se pudo cargar tu perfil',
                        style:
                            const TextStyle(color: AppColors.estadoVencido),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => ref.invalidate(profileProvider),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            data: (p) => [
              Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: AppColors.ember.withValues(alpha: 0.12),
                    backgroundImage:
                        p.foto != null ? NetworkImage(p.foto!) : null,
                    child: p.foto == null
                        ? Text(p.inicial,
                            style: const TextStyle(
                                color: AppColors.ember,
                                fontWeight: FontWeight.w700,
                                fontSize: 26))
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.nombreCompleto, style: text.titleLarge),
                        const SizedBox(height: 2),
                        Text(
                          'CC ${p.cedula}${p.edad != null ? ' · ${p.edad} años' : ''}',
                          style: muted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                child: Column(
                  children: [
                    _Opcion(
                      icono: Icons.person_outline_rounded,
                      titulo: 'Datos personales',
                      subtitulo: 'Contacto, dirección y fecha de nacimiento',
                      onTap: () => context.push('/profile/edit'),
                    ),
                    const Divider(height: 1),
                    _Opcion(
                      icono: Icons.restaurant_rounded,
                      titulo: 'Preferencias de alimentación',
                      subtitulo: p.alimentacion == null
                          ? 'Aún sin completar'
                          : 'Completadas',
                      onTap: () => context.push('/profile/nutrition'),
                    ),
                    const Divider(height: 1),
                    _Opcion(
                      icono: Icons.fitness_center_rounded,
                      titulo: 'Perfil de entrenamiento',
                      subtitulo: p.entrenamiento == null
                          ? 'Aún sin completar'
                          : 'Completado',
                      onTap: () => context.push('/profile/training'),
                    ),
                    const Divider(height: 1),
                    _Opcion(
                      icono: Icons.lock_outline_rounded,
                      titulo: 'Cambiar contraseña',
                      subtitulo: 'Actualiza tu clave de acceso',
                      onTap: () => context.push('/profile/password'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Tus preferencias se piden una sola vez: la IA las usará para personalizar tus rutinas y tu alimentación.',
                  style: text.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
              ),
              if (gym != null &&
                  (gym.info.telefono.isNotEmpty ||
                      gym.info.direccion.isNotEmpty)) ...[
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(gym.info.nombre, style: text.titleMedium),
                        const SizedBox(height: 8),
                        if (gym.info.telefono.isNotEmpty)
                          _DatoContacto(
                              Icons.phone_rounded, gym.info.telefono),
                        if (gym.info.direccion.isNotEmpty)
                          _DatoContacto(
                              Icons.place_rounded, gym.info.direccion),
                        if (gym.info.horarioAtencion.isNotEmpty)
                          _DatoContacto(Icons.schedule_rounded,
                              gym.info.horarioAtencion),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _cerrarSesion(context, ref),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Opcion extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;
  const _Opcion({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icono, color: AppColors.ember),
      title: Text(titulo),
      subtitle: Text(subtitulo),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _DatoContacto extends StatelessWidget {
  final IconData icono;
  final String texto;
  const _DatoContacto(this.icono, this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }
}
