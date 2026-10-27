import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import '../../../providers/store_provider.dart';

class ProductoFormDialog extends ConsumerStatefulWidget {
  final Producto? producto;
  const ProductoFormDialog({super.key, this.producto});

  @override
  ConsumerState<ProductoFormDialog> createState() =>
      _ProductoFormDialogState();
}

class _ProductoFormDialogState extends ConsumerState<ProductoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _categoriaCtrl;
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _precioCompraCtrl;
  late final TextEditingController _precioVentaCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _stockMinimoCtrl;
  bool _guardando = false;
  String? _error;

  bool get _esEdicion => widget.producto != null;

  @override
  void initState() {
    super.initState();
    final p = widget.producto;
    _nombreCtrl = TextEditingController(text: p?.nombre ?? '');
    _categoriaCtrl = TextEditingController(text: p?.categoria ?? '');
    _descripcionCtrl = TextEditingController(text: p?.descripcion ?? '');
    _precioCompraCtrl =
        TextEditingController(text: p?.precioCompra.toStringAsFixed(0) ?? '');
    _precioVentaCtrl =
        TextEditingController(text: p?.precioVenta.toStringAsFixed(0) ?? '');
    _stockCtrl = TextEditingController(text: p?.stock.toString() ?? '0');
    _stockMinimoCtrl =
        TextEditingController(text: p?.stockMinimo.toString() ?? '5');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _categoriaCtrl.dispose();
    _descripcionCtrl.dispose();
    _precioCompraCtrl.dispose();
    _precioVentaCtrl.dispose();
    _stockCtrl.dispose();
    _stockMinimoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });

    final notifier = ref.read(storeProvider.notifier);
    final error = _esEdicion
        ? await notifier.actualizarProducto(
            widget.producto!.id,
            nombre: _nombreCtrl.text.trim(),
            precioCompra: double.parse(_precioCompraCtrl.text),
            precioVenta: double.parse(_precioVentaCtrl.text),
            stockMinimo: int.tryParse(_stockMinimoCtrl.text),
            categoria: _categoriaCtrl.text.trim(),
            descripcion: _descripcionCtrl.text.trim(),
          )
        : await notifier.crearProducto(
            nombre: _nombreCtrl.text.trim(),
            precioCompra: double.parse(_precioCompraCtrl.text),
            precioVenta: double.parse(_precioVentaCtrl.text),
            stock: int.parse(_stockCtrl.text),
            stockMinimo: int.tryParse(_stockMinimoCtrl.text),
            categoria: _categoriaCtrl.text.trim(),
            descripcion: _descripcionCtrl.text.trim(),
          );

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

  String? _validarNumero(String? v, {bool permiteCero = false}) {
    final n = double.tryParse(v ?? '');
    if (n == null || (permiteCero ? n < 0 : n <= 0)) return 'Inválido';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_esEdicion ? 'Editar producto' : 'Nuevo producto',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _nombreCtrl,
                          decoration: const InputDecoration(labelText: 'Nombre'),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _categoriaCtrl,
                          decoration:
                              const InputDecoration(labelText: 'Categoría'),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _precioCompraCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                    labelText: 'Precio compra', prefixText: '\$ '),
                                validator: _validarNumero,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _precioVentaCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                    labelText: 'Precio venta', prefixText: '\$ '),
                                validator: _validarNumero,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _stockCtrl,
                                enabled: !_esEdicion,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Stock inicial',
                                  helperText: _esEdicion
                                      ? 'Se ajusta solo con ventas'
                                      : null,
                                ),
                                validator: (v) =>
                                    _validarNumero(v, permiteCero: true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _stockMinimoCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                    labelText: 'Stock mínimo'),
                                validator: (v) =>
                                    _validarNumero(v, permiteCero: true),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _descripcionCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Descripción (opcional)'),
                          maxLines: 2,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Text(_error!,
                              style:
                                  const TextStyle(color: AppColors.estadoVencido)),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
                      onPressed: _guardando ? null : _guardar,
                      child: _guardando
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(_esEdicion ? 'Guardar cambios' : 'Crear producto'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
