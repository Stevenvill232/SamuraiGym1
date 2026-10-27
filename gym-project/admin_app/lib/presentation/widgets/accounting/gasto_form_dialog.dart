import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import '../../../providers/accounting_provider.dart';

const _categorias = [
  'LUZ',
  'AGUA',
  'NOMINA',
  'ARRIENDO',
  'INTERNET',
  'MANTENIMIENTO',
  'IMPLEMENTOS',
  'OTRO',
];

const _metodosPago = [
  'EFECTIVO',
  'TRANSFERENCIA',
  'NEQUI',
  'DAVIPLATA',
  'TARJETA',
  'OTRO',
];

class GastoFormDialog extends ConsumerStatefulWidget {
  const GastoFormDialog({super.key});

  @override
  ConsumerState<GastoFormDialog> createState() => _GastoFormDialogState();
}

class _GastoFormDialogState extends ConsumerState<GastoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  final _observacionCtrl = TextEditingController();
  String _categoria = 'OTRO';
  String _metodoPago = 'EFECTIVO';
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    _valorCtrl.dispose();
    _observacionCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });

    final error = await ref.read(accountingProvider.notifier).registrarGasto(
          categoria: _categoria,
          descripcion: _descripcionCtrl.text.trim(),
          valor: double.parse(_valorCtrl.text),
          metodoPago: _metodoPago,
          observacion: _observacionCtrl.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Registrar gasto',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _categoria,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: _categorias
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _categoria = v!),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descripcionCtrl,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _valorCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Valor', prefixText: '\$ '),
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          if (n == null || n <= 0) return 'Valor inválido';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _metodoPago,
                        decoration:
                            const InputDecoration(labelText: 'Método de pago'),
                        items: _metodosPago
                            .map((m) =>
                                DropdownMenuItem(value: m, child: Text(m)))
                            .toList(),
                        onChanged: (v) => setState(() => _metodoPago = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _observacionCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Observación (opcional)'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!,
                      style: const TextStyle(color: AppColors.estadoVencido)),
                ],
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
                          : const Text('Registrar'),
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
