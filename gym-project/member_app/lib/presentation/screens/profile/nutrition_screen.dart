import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';
import '../../../data/member_models.dart';
import '../../../providers/member_providers.dart';

const _objetivos = [
  'Perder grasa',
  'Ganar masa muscular',
  'Mantener peso',
  'Mejorar rendimiento',
  'Salud general',
];
const _dietas = [
  'Omnívora',
  'Vegetariana',
  'Vegana',
  'Pescetariana',
  'Keto',
  'Otra',
];

/// Preferencias de alimentación: se piden UNA sola vez y la IA las reutiliza
/// para todas las recomendaciones (sección 17 del proyecto).
class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(profileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Preferencias de alimentación')),
      body: perfil.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            e is ApiException ? e.message : 'No se pudo cargar tu perfil',
            style: const TextStyle(color: AppColors.estadoVencido),
          ),
        ),
        data: (p) => _NutritionForm(inicial: p.alimentacion),
      ),
    );
  }
}

class _NutritionForm extends ConsumerStatefulWidget {
  final PerfilAlimentacion? inicial;
  const _NutritionForm({this.inicial});

  @override
  ConsumerState<_NutritionForm> createState() => _NutritionFormState();
}

class _NutritionFormState extends ConsumerState<_NutritionForm> {
  String? _objetivo;
  String? _dieta;
  int? _comidas;
  late final TextEditingController _presupuestoCtrl;
  late List<String> _noConsumo;
  late List<String> _noGustan;
  late List<String> _alergias;
  late List<String> _restricciones;
  late List<String> _preferencias;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final i = widget.inicial;
    _objetivo = i?.objetivo;
    _dieta = i?.tipoDieta;
    _comidas = i?.numeroComidas;
    _presupuestoCtrl = TextEditingController(
        text: i?.presupuesto != null ? i!.presupuesto!.toStringAsFixed(0) : '');
    _noConsumo = [...?i?.alimentosNoConsumidos];
    _noGustan = [...?i?.alimentosNoGustan];
    _alergias = [...?i?.alergias];
    _restricciones = [...?i?.restricciones];
    _preferencias = [...?i?.preferencias];
  }

  @override
  void dispose() {
    _presupuestoCtrl.dispose();
    super.dispose();
  }

  Widget _chips(
    String titulo,
    List<String> opciones,
    String? seleccion,
    ValueChanged<String?> onChanged,
  ) {
    // Si lo guardado no está en la lista (valor propio), igual se muestra.
    final todas = [
      ...opciones,
      if (seleccion != null && !opciones.contains(seleccion)) seleccion,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final o in todas)
              ChoiceChip(
                label: Text(o),
                selected: seleccion == o,
                onSelected: (s) => onChanged(s ? o : null),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _guardar() async {
    final txt = _presupuestoCtrl.text.trim();
    final presupuesto = txt.isEmpty ? null : double.tryParse(txt.replaceAll(',', '.'));
    if (txt.isNotEmpty && (presupuesto == null || presupuesto < 0)) {
      setState(() => _error = 'El presupuesto debe ser un número');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(memberRepositoryProvider).guardarAlimentacion(
            PerfilAlimentacion(
              objetivo: _objetivo,
              tipoDieta: _dieta,
              numeroComidas: _comidas,
              presupuesto: presupuesto,
              alimentosNoConsumidos: _noConsumo,
              alimentosNoGustan: _noGustan,
              alergias: _alergias,
              restricciones: _restricciones,
              preferencias: _preferencias,
            ),
          );
      ref.invalidate(profileProvider);
      if (!mounted) return;
      messenger.showSnackBar(
          const SnackBar(content: Text('Preferencias guardadas')));
      context.pop();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _guardando = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const separador = SizedBox(height: 24);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _chips('Objetivo', _objetivos, _objetivo,
            (v) => setState(() => _objetivo = v)),
        separador,
        _chips('Tipo de alimentación', _dietas, _dieta,
            (v) => setState(() => _dieta = v)),
        separador,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Número de comidas al día',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final n in [2, 3, 4, 5, 6])
                  ChoiceChip(
                    label: Text('$n'),
                    selected: _comidas == n,
                    onSelected: (s) => setState(() => _comidas = s ? n : null),
                  ),
              ],
            ),
          ],
        ),
        separador,
        TextField(
          controller: _presupuestoCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Presupuesto diario aproximado (opcional)',
            prefixText: '\$ ',
          ),
        ),
        separador,
        TagsEditor(
          label: 'Alimentos que no puedo consumir',
          hint: 'Ej. lactosa, gluten',
          values: _noConsumo,
          onChanged: (v) => setState(() => _noConsumo = v),
        ),
        separador,
        TagsEditor(
          label: 'Alimentos que no me gustan',
          hint: 'Ej. brócoli',
          values: _noGustan,
          onChanged: (v) => setState(() => _noGustan = v),
        ),
        separador,
        TagsEditor(
          label: 'Alergias',
          hint: 'Ej. maní, mariscos',
          values: _alergias,
          onChanged: (v) => setState(() => _alergias = v),
        ),
        separador,
        TagsEditor(
          label: 'Restricciones',
          hint: 'Ej. sin azúcar',
          values: _restricciones,
          onChanged: (v) => setState(() => _restricciones = v),
        ),
        separador,
        TagsEditor(
          label: 'Preferencias (lo que sí me gusta)',
          hint: 'Ej. pollo, avena',
          values: _preferencias,
          onChanged: (v) => setState(() => _preferencias = v),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: AppColors.estadoVencido)),
        ],
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Guardar preferencias'),
        ),
      ],
    );
  }
}
