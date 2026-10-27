import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_models/shared_models.dart';
import '../../../providers/store_provider.dart';
import '../../widgets/store/producto_form_dialog.dart';
import '../../widgets/store/venta_dialog.dart';

final _formatoMoneda =
    NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

class StoreScreen extends ConsumerWidget {
  const StoreScreen({super.key});

  Future<void> _abrirFormularioProducto(BuildContext context, WidgetRef ref,
      {Producto? producto}) async {
    final guardado = await showDialog<bool>(
      context: context,
      builder: (_) => ProductoFormDialog(producto: producto),
    );
    if (guardado == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
            producto == null ? 'Producto creado' : 'Producto actualizado')),
      );
    }
  }

  Future<void> _abrirVenta(BuildContext context, WidgetRef ref) async {
    final vendido = await showDialog<bool>(
      context: context,
      builder: (_) => const VentaDialog(),
    );
    if (vendido == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venta registrada correctamente')),
      );
    }
  }

  Future<void> _confirmarEliminar(
      BuildContext context, WidgetRef ref, Producto p) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Desactivar producto'),
        content: Text('¿Seguro que deseas desactivar "${p.nombre}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.estadoVencido),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      await ref.read(storeProvider.notifier).eliminarProducto(p.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storeProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'nueva-venta',
            onPressed: () => _abrirVenta(context, ref),
            icon: const Icon(Icons.point_of_sale_rounded),
            label: const Text('Nueva venta'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'nuevo-producto',
            backgroundColor: AppColors.graphite,
            onPressed: () => _abrirFormularioProducto(context, ref),
            icon: const Icon(Icons.add_box_outlined),
            label: const Text('Nuevo producto'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tienda', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'Inventario de productos y registro de ventas',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(state.error!,
                    style: const TextStyle(color: AppColors.estadoVencido)),
              ),
            Expanded(
              child: state.cargando && state.productos.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.productos.isEmpty
                      ? Center(
                          child: Text('Todavía no hay productos registrados',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.textMuted)))
                      : RefreshIndicator(
                          onRefresh: () => ref.read(storeProvider.notifier).cargar(),
                          child: ListView.builder(
                            itemCount: state.productos.length,
                            itemBuilder: (context, i) {
                              final p = state.productos[i];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  title: Text(p.nombre,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  subtitle: Text(
                                    '${p.categoria ?? "Sin categoría"} · '
                                    '${_formatoMoneda.format(p.precioVenta)}',
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: p.stockBajo
                                        ? AppColors.estadoVencido.withValues(alpha: 0.12)
                                        : AppColors.background,
                                    child: Text(
                                      '${p.stock}',
                                      style: TextStyle(
                                        color: p.stockBajo
                                            ? AppColors.estadoVencido
                                            : AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (p.stockBajo)
                                        const Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: Icon(Icons.warning_amber_rounded,
                                              color: AppColors.estadoPorVencer,
                                              size: 20),
                                        ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined),
                                        onPressed: () => _abrirFormularioProducto(
                                            context, ref, producto: p),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded,
                                            color: AppColors.estadoVencido),
                                        onPressed: () =>
                                            _confirmarEliminar(context, ref, p),
                                      ),
                                    ],
                                  ),
                                ),
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
