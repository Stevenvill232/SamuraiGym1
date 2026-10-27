import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/plans_provider.dart';

/// Precios sugeridos por tipo de plan. Son solo un punto de partida editable
/// por el usuario en el formulario: la Fase de Configuración los hará
/// ajustables desde la app sin tocar código (ver ARQUITECTURA.md).
const Map<TipoPlan, double> kPreciosSugeridos = {
  TipoPlan.gimnasioSesion: 8000,
  TipoPlan.gimnasioQuincena: 40000,
  TipoPlan.gimnasioMes: 70000,
  TipoPlan.tiquetera10: 60000,
  TipoPlan.tiquetera15: 85000,
  TipoPlan.tiquetera20: 110000,
  TipoPlan.tiquetera30: 150000,
  TipoPlan.boxeo: 80000,
  TipoPlan.karate: 80000,
  TipoPlan.mma: 90000,
};

const _metodosPago = [
  'EFECTIVO',
  'TRANSFERENCIA',
  'NEQUI',
  'DAVIPLATA',
  'TARJETA',
  'OTRO',
];

class PlanFormDialog extends ConsumerStatefulWidget {
  /// Si ya se conoce el miembro (ej. viniendo desde su ficha), se preselecciona
  /// y no se muestra el buscador.
  final String? miembroIdInicial;
  final String? nombreMiembroInicial;

  const PlanFormDialog({
    super.key,
    this.miembroIdInicial,
    this.nombreMiembroInicial,
  });

  @override
  ConsumerState<PlanFormDialog> createState() => _PlanFormDialogState();
}

class _PlanFormDialogState extends ConsumerState<PlanFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _precioCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();
  final _busquedaCtrl = TextEditingController();

  String? _miembroId;
  String? _nombreMiembro;
  TipoPlan _tipoPlan = TipoPlan.gimnasioMes;
  String _metodoPago = 'EFECTIVO';
  String? _horarioId;
  bool _guardando = false;
  String? _error;

  List<Usuario> _resultadosBusqueda = [];
  bool _buscando = false;

  bool get _esDeporte =>
      _tipoPlan == TipoPlan.boxeo ||
      _tipoPlan == TipoPlan.karate ||
      _tipoPlan == TipoPlan.mma;

  @override
  void initState() {
    super.initState();
    _miembroId = widget.miembroIdInicial;
    _nombreMiembro = widget.nombreMiembroInicial;
    _precioCtrl.text = kPreciosSugeridos[_tipoPlan]!.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _precioCtrl.dispose();
    _observacionesCtrl.dispose();
    _busquedaCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscarMiembros(String texto) async {
    if (texto.trim().isEmpty) {
      setState(() => _resultadosBusqueda = []);
      return;
    }
    setState(() => _buscando = true);
    final api = ref.read(apiClientProvider);
    try {
      final data = await api.getList('/users', query: {
        'role': 'MIEMBRO',
        'search': texto,
      });
      if (!mounted) return;
      setState(() {
        _resultadosBusqueda = data.map((j) => Usuario.fromJson(j)).toList();
        _buscando = false;
      });
    } catch (_) {
      if (mounted) setState(() => _buscando = false);
    }
  }

  void _onTipoPlanChanged(TipoPlan? nuevo) {
    if (nuevo == null) return;
    setState(() {
      _tipoPlan = nuevo;
      _precioCtrl.text = kPreciosSugeridos[nuevo]!.toStringAsFixed(0);
      _horarioId = null;
    });
  }

  Future<void> _guardar() async {
    if (_miembroId == null) {
      setState(() => _error = 'Selecciona un miembro');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_esDeporte && _horarioId == null) {
      setState(() => _error = 'Selecciona un horario');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    final error = await ref.read(plansProvider.notifier).crearPlan(
          miembroId: _miembroId!,
          tipoPlan: _tipoPlan,
          precio: double.parse(_precioCtrl.text),
          metodoPago: _metodoPago,
          horarioId: _horarioId,
          observaciones: _observacionesCtrl.text.trim(),
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
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nuevo plan', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSelectorMiembro(),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<TipoPlan>(
                          value: _tipoPlan,
                          decoration:
                              const InputDecoration(labelText: 'Tipo de plan'),
                          items: TipoPlan.values
                              .map((t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t.etiqueta),
                                  ))
                              .toList(),
                          onChanged: _onTipoPlanChanged,
                        ),
                        if (_esDeporte) ...[
                          const SizedBox(height: 16),
                          _buildSelectorHorario(),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _precioCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                    labelText: 'Precio', prefixText: '\$ '),
                                validator: (v) {
                                  final n = double.tryParse(v ?? '');
                                  if (n == null || n <= 0) return 'Precio inválido';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _metodoPago,
                                decoration: const InputDecoration(
                                    labelText: 'Método de pago'),
                                items: _metodosPago
                                    .map((m) => DropdownMenuItem(
                                        value: m, child: Text(m)))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _metodoPago = v!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _observacionesCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Observaciones (opcional)'),
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
                          : const Text('Registrar plan'),
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

  Widget _buildSelectorMiembro() {
    if (_miembroId != null && widget.miembroIdInicial != null) {
      // Miembro preseleccionado (viene desde su ficha): no se puede cambiar.
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_rounded, color: AppColors.textMuted, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(_nombreMiembro ?? 'Miembro seleccionado')),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_miembroId != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Chip(
              avatar: const Icon(Icons.check_circle_rounded,
                  color: AppColors.estadoActivo, size: 18),
              label: Text(_nombreMiembro ?? ''),
              onDeleted: () => setState(() {
                _miembroId = null;
                _nombreMiembro = null;
              }),
            ),
          )
        else ...[
          TextField(
            controller: _busquedaCtrl,
            decoration: const InputDecoration(
              labelText: 'Buscar miembro por cédula o nombre',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: _buscarMiembros,
          ),
          if (_buscando)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            ),
          if (_resultadosBusqueda.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 6),
              constraints: const BoxConstraints(maxHeight: 160),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderSubtle),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _resultadosBusqueda.length,
                itemBuilder: (context, i) {
                  final u = _resultadosBusqueda[i];
                  return ListTile(
                    dense: true,
                    title: Text(u.nombreCompleto),
                    subtitle: Text('CC ${u.cedula}'),
                    onTap: () => setState(() {
                      _miembroId = u.id;
                      _nombreMiembro = u.nombreCompleto;
                      _resultadosBusqueda = [];
                      _busquedaCtrl.clear();
                    }),
                  );
                },
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildSelectorHorario() {
    final deporte = _tipoPlan.toApi(); // BOXEO | KARATE | MMA
    final horariosAsync = ref.watch(horariosProvider(deporte));

    return horariosAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const Text('No se pudieron cargar los horarios',
          style: TextStyle(color: AppColors.estadoVencido)),
      data: (horarios) {
        if (horarios.isEmpty) {
          return const Text(
            'No hay horarios configurados para este deporte todavía.',
            style: TextStyle(color: AppColors.textMuted),
          );
        }
        return DropdownButtonFormField<String>(
          value: _horarioId,
          decoration: const InputDecoration(labelText: 'Horario'),
          items: horarios
              .map((h) => DropdownMenuItem(
                    value: h['id'] as String,
                    child: Text('${h['dia']} · ${h['horaInicio']} - ${h['horaFin']}'),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _horarioId = v),
        );
      },
    );
  }
}
