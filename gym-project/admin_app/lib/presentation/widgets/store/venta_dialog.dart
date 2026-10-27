import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_models/shared_models.dart';
import '../../../providers/store_provider.dart';

final _formatoMoneda =
    NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

const _metodosPago = [
  'EFECTIVO',
  'TRANSFERENCIA',
  'NEQUI',
  'DAVIPLATA',
  'TARJETA',
  'OTRO',
];

class VentaDialog extends ConsumerStatefulWidget {
  const VentaDialog({super.key});

  @override
  ConsumerState<VentaDialog> createState() => _VentaDialogState();
}

class _VentaDialogState extends ConsumerState<VentaDialog> {
  final Map<String, int> _cantidades = {};
  String _metodoPago = 'EFECTIVO';
  bool _guardando = false;
  String? _error;

  void _cambiarCantidad(Producto p, int delta) {
    setState(() {
      final actual = _cantidades[p.id] ?? 0;
      final nueva = (actual + delta).clamp(0, p.stock);
      if (nueva == 0) {
        _cantidades.remove(p.id);
      } else {
        _cantidades[p.id] = nueva;
      }
    });
  }

  double _total(List<Producto> productos) {
    double total = 0;
    for (final entry in _cantidades.entries) {
      final producto = productos.firstWhere((p) => p.id == entry.key);
      total += producto.precioVenta * entry.value;
    }
    return total;
  }

  Future<void> _confirmarVenta() async {
    if (_cantidades.isEmpty) {
      setState(() => _error = 'Selecciona al menos un producto');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });

    final items = _cantidades.entries
        .map((e) => {'productoId': e.key, 'cantidad': e.value})
        .toList();

    final error =
        await ref.read(storeProvider.notifier).crearVenta(items, _metodoPago);

    if (!mounted) return;
    if (error != null) {
      setState(() {
        _guardando = false;
        _error = error;
      });
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productos = ref.watch(storeProvider).productos;
    final disponibles = productos.where((p) => p.stock > 0).toList();

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nueva venta', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Flexible(
                child: disponibles.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No hay productos con stock disponible.',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: disponibles.length,
                        itemBuilder: (context, i) {
                          final p = disponibles[i];
                          final cantidad = _cantidades[p.id] ?? 0;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(p.nombre),
                            subtitle: Text(
                                '${_formatoMoneda.format(p.precioVenta)} · stock: ${p.stock}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: cantidad > 0
                                      ? () => _cambiarCantidad(p, -1)
                                      : null,
                                ),
                                SizedBox(
                                  width: 24,
                                  child: Text('$cantidad',
                                      textAlign: TextAlign.center),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: cantidad < p.stock
                                      ? () => _cambiarCantidad(p, 1)
                                      : null,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _metodoPago,
                      decoration:
                          const InputDecoration(labelText: 'Método de pago'),
                      items: _metodosPago
                          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (v) => setState(() => _metodoPago = v!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Total', style: TextStyle(color: AppColors.textMuted)),
                      Text(
                        _formatoMoneda.format(_total(productos)),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: AppColors.estadoVencido)),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _guardando
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _guardando ? null : _confirmarVenta,
                    child: _guardando
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Confirmar venta'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
