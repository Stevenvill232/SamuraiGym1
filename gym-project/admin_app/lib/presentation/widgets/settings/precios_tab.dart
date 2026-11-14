import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import '../../../providers/settings_provider.dart';
import 'settings_common.dart';

class PreciosTab extends ConsumerStatefulWidget {
  final AppSettings settings;
  const PreciosTab({super.key, required this.settings});

  @override
  ConsumerState<PreciosTab> createState() => _PreciosTabState();
}

class _PreciosTabState extends ConsumerState<PreciosTab> {
  late final Map<TipoPlan, TextEditingController> _ctrls;
  late final TextEditingController _factorCtrl;
  bool _guardando = false;
  String? _error;

  static String _fmtFactor(double f) =>
      f == f.roundToDouble() ? f.toStringAsFixed(0) : f.toString();

  @override
  void initState() {
    super.initState();
    _ctrls = {
      for (final t in TipoPlan.values)
        t: TextEditingController(
            text: widget.settings.precioDe(t).toStringAsFixed(0)),
    };
    _factorCtrl = TextEditingController(
        text: _fmtFactor(widget.settings.tiqueteraFactorVigencia));
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    _factorCtrl.dispose();
    super.dispose();
  }

  double? _num(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

  Future<void> _guardar() async {
    final precios = <String, double>{};
    for (final e in _ctrls.entries) {
      final v = _num(e.value.text);
      if (v == null || v <= 0) {
        setState(() => _error = 'Revisa el precio de "${e.key.etiqueta}"');
        return;
      }
      precios[e.key.toApi()] = v;
    }
    final factor = _num(_factorCtrl.text);
    if (factor == null || factor < 1 || factor > 10) {
      setState(() => _error = 'El factor de vigencia debe estar entre 1 y 10');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });
    final error =
        await ref.read(settingsProvider.notifier).guardarVarias({
      'precios_planes': precios,
      'tiquetera_factor_vigencia': factor,
    });
    if (!mounted) return;
    setState(() {
      _guardando = false;
      _error = error;
    });
    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Precios guardados. Los planes ya vendidos no cambian.'),
      ));
    }
  }

  Widget _fila(TipoPlan t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(child: Text(t.etiqueta)),
            SizedBox(
              width: 170,
              child: TextField(
                controller: _ctrls[t],
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(prefixText: '\$ ', isDense: true),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return TabScroll(
      children: [
        SeccionCard(
          titulo: 'Gimnasio',
          descripcion:
              'Precio sugerido al registrar un plan. Los cambios aplican a las próximas ventas; los planes ya vendidos conservan lo que se pagó.',
          child: Column(children: [
            _fila(TipoPlan.gimnasioSesion),
            _fila(TipoPlan.gimnasioQuincena),
            _fila(TipoPlan.gimnasioMes),
          ]),
        ),
        SeccionCard(
          titulo: 'Tiqueteras',
          child: Column(children: [
            _fila(TipoPlan.tiquetera10),
            _fila(TipoPlan.tiquetera15),
            _fila(TipoPlan.tiquetera20),
            _fila(TipoPlan.tiquetera30),
          ]),
        ),
        SeccionCard(
          titulo: 'Boxeo, Karate y MMA',
          child: Column(children: [
            _fila(TipoPlan.boxeo),
            _fila(TipoPlan.karate),
            _fila(TipoPlan.mma),
          ]),
        ),
        SeccionCard(
          titulo: 'Vigencia de las tiqueteras',
          descripcion:
              'Una tiquetera de N días debe usarse dentro de N × factor días calendario. '
              'Ejemplo con factor 2: una tiquetera de 10 días vence a los 20 días.',
          child: SizedBox(
            width: 200,
            child: TextField(
              controller: _factorCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Factor de vigencia', isDense: true),
            ),
          ),
        ),
        BotonGuardar(
            guardando: _guardando, error: _error, onPressed: _guardar),
      ],
    );
  }
}
