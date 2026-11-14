import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import '../../../providers/settings_provider.dart';

/// Contenedor con scroll y ancho máximo para el contenido de una pestaña.
class TabScroll extends StatelessWidget {
  final List<Widget> children;
  const TabScroll({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// Tarjeta con título y descripción opcional.
class SeccionCard extends StatelessWidget {
  final String titulo;
  final String? descripcion;
  final Widget child;
  const SeccionCard({
    super.key,
    required this.titulo,
    required this.child,
    this.descripcion,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: Theme.of(context).textTheme.titleMedium),
            if (descripcion != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  descripcion!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textMuted),
                ),
              ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

/// Espera a que la configuración llegue del servidor antes de construir la
/// pestaña, para que los campos se inicialicen con los valores reales.
class SettingsGate extends ConsumerWidget {
  final Widget Function(AppSettings settings) builder;
  const SettingsGate({super.key, required this.builder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(settingsProvider);
    if (!st.cargado) {
      if (st.error != null) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(st.error!,
                  style: const TextStyle(color: AppColors.estadoVencido)),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.read(settingsProvider.notifier).cargar(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }
    return builder(st.settings);
  }
}

/// Botón "Guardar" con spinner y mensaje de error, común a las pestañas.
class BotonGuardar extends StatelessWidget {
  final bool guardando;
  final String? error;
  final VoidCallback onPressed;
  final String texto;
  const BotonGuardar({
    super.key,
    required this.guardando,
    required this.onPressed,
    this.error,
    this.texto = 'Guardar cambios',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(error!,
                style: const TextStyle(color: AppColors.estadoVencido)),
          ),
        ElevatedButton(
          onPressed: guardando ? null : onPressed,
          child: guardando
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(texto),
        ),
      ],
    );
  }
}
