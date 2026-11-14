import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import '../../../providers/settings_provider.dart';
import 'settings_common.dart';

/// Categorías de gastos, métodos de pago y stock mínimo predeterminado.
class CatalogosTab extends ConsumerStatefulWidget {
  final AppSettings settings;
  const CatalogosTab({super.key, required this.settings});

  @override
  ConsumerState<CatalogosTab> createState() => _CatalogosTabState();
}

class _CatalogosTabState extends ConsumerState<CatalogosTab> {
  late List<String> _categorias;
  late List<String> _metodos;
  late final TextEditingController _stockCtrl;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _categorias = [...widget.settings.categoriasGasto];
    _metodos = [...widget.settings.metodosPago];
    _stockCtrl = TextEditingController(
        text: widget.settings.stockMinimoDefault.toString());
  }

  @override
  void dispose() {
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final stock = int.tryParse(_stockCtrl.text.trim());
    if (_categorias.isEmpty || _metodos.isEmpty) {
      setState(() => _error =
          'Debe haber al menos una categoría y un método de pago');
      return;
    }
    if (stock == null || stock < 0) {
      setState(() => _error = 'El stock mínimo debe ser un número entero');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    final error = await ref.read(settingsProvider.notifier).guardarVarias({
      'categorias_gasto': _categorias,
      'metodos_pago': _metodos,
      'stock_minimo_default': stock,
    });
    if (!mounted) return;
    setState(() {
      _guardando = false;
      _error = error;
    });
    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Catálogos guardados')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return TabScroll(
      children: [
        SeccionCard(
          titulo: 'Categorías de gastos',
          descripcion:
              'Quitar o renombrar una categoría no modifica los gastos ya registrados.',
          child: TagsEditor(
            label: 'Categorías',
            values: _categorias,
            onChanged: (v) => setState(() => _categorias = v),
            hint: 'Ej. Publicidad',
          ),
        ),
        SeccionCard(
          titulo: 'Métodos de pago',
          descripcion:
              'Aparecen al registrar planes, ventas y gastos. Los pagos anteriores conservan el método con el que se hicieron.',
          child: TagsEditor(
            label: 'Métodos de pago',
            values: _metodos,
            onChanged: (v) => setState(() => _metodos = v),
            hint: 'Ej. Bancolombia',
          ),
        ),
        SeccionCard(
          titulo: 'Inventario',
          descripcion:
              'Stock mínimo que se propone al crear un producto nuevo. Cada producto puede tener el suyo.',
          child: SizedBox(
            width: 200,
            child: TextField(
              controller: _stockCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Stock mínimo predeterminado', isDense: true),
            ),
          ),
        ),
        BotonGuardar(
            guardando: _guardando, error: _error, onPressed: _guardar),
      ],
    );
  }
}
