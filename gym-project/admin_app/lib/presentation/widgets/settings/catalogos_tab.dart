import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import '../../../providers/settings_provider.dart';
import 'settings_common.dart';

/// Categorías de gastos, métodos de pago y stock mínimo predeterminado.
///
/// Las listas se guardan AL INSTANTE: cada vez que agregas o quitas un
/// elemento se envía al servidor, y si falla se deshace y se muestra el error.
/// (Antes dependían de un botón "Guardar" al final de la página y, si no se
/// pulsaba, los cambios se perdían al cambiar de pestaña.)
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
  bool _guardandoStock = false;
  String? _errorStock;

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

  void _aviso(String texto) {
    final m = ScaffoldMessenger.of(context);
    m.hideCurrentSnackBar();
    m.showSnackBar(SnackBar(
      content: Text(texto),
      duration: const Duration(seconds: 3),
    ));
  }

  /// Aplica el cambio en pantalla de inmediato, lo guarda, y lo deshace si
  /// el servidor lo rechaza.
  Future<void> _cambiarLista(
    String clave,
    List<String> nueva,
    List<String> anterior,
    void Function(List<String>) asignar,
  ) async {
    if (nueva.isEmpty) {
      _aviso('Debe quedar al menos un elemento en la lista');
      return;
    }
    setState(() => asignar(nueva));
    final error =
        await ref.read(settingsProvider.notifier).guardarVarias({clave: nueva});
    if (!mounted) return;
    if (error != null) {
      setState(() => asignar(anterior));
      _aviso('No se pudo guardar: $error');
    } else {
      _aviso('Cambios guardados');
    }
  }

  Future<void> _guardarStock() async {
    final stock = int.tryParse(_stockCtrl.text.trim());
    if (stock == null || stock < 0) {
      setState(() => _errorStock = 'El stock mínimo debe ser un número entero');
      return;
    }
    setState(() {
      _guardandoStock = true;
      _errorStock = null;
    });
    final error = await ref
        .read(settingsProvider.notifier)
        .guardarVarias({'stock_minimo_default': stock});
    if (!mounted) return;
    setState(() {
      _guardandoStock = false;
      _errorStock = error;
    });
    if (error == null) _aviso('Stock mínimo guardado');
  }

  @override
  Widget build(BuildContext context) {
    return TabScroll(
      children: [
        SeccionCard(
          titulo: 'Categorías de gastos',
          descripcion:
              'Se guardan al instante. Quitar o renombrar una categoría no modifica los gastos ya registrados.',
          child: TagsEditor(
            label: 'Categorías',
            values: _categorias,
            onChanged: (v) => _cambiarLista(
                'categorias_gasto', v, _categorias, (l) => _categorias = l),
            hint: 'Ej. Publicidad',
          ),
        ),
        SeccionCard(
          titulo: 'Métodos de pago',
          descripcion:
              'Se guardan al instante. Aparecen al registrar planes, ventas y gastos; los pagos anteriores conservan el método con el que se hicieron.',
          child: TagsEditor(
            label: 'Métodos de pago',
            values: _metodos,
            onChanged: (v) =>
                _cambiarLista('metodos_pago', v, _metodos, (l) => _metodos = l),
            hint: 'Ej. Bancolombia',
          ),
        ),
        SeccionCard(
          titulo: 'Inventario',
          descripcion:
              'Stock mínimo que se propone al crear un producto nuevo. Cada producto puede tener el suyo.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 240,
                child: TextField(
                  controller: _stockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Stock mínimo predeterminado', isDense: true),
                ),
              ),
              const SizedBox(height: 14),
              BotonGuardar(
                guardando: _guardandoStock,
                error: _errorStock,
                onPressed: _guardarStock,
                texto: 'Guardar stock mínimo',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
