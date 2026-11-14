import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';
import '../../../data/member_models.dart';
import '../../../providers/member_providers.dart';

const _objetivos = [
  'Fuerza',
  'Hipertrofia',
  'Resistencia',
  'Pérdida de peso',
  'Movilidad',
  'Salud general',
];
const _niveles = {
  'PRINCIPIANTE': 'Principiante',
  'INTERMEDIO': 'Intermedio',
  'AVANZADO': 'Avanzado',
};
const _dias = {
  'LUNES': 'Lun',
  'MARTES': 'Mar',
  'MIERCOLES': 'Mié',
  'JUEVES': 'Jue',
  'VIERNES': 'Vie',
  'SABADO': 'Sáb',
  'DOMINGO': 'Dom',
};
const _duraciones = [30, 45, 60, 90];
const _equipos = [
  'Mancuernas',
  'Barra',
  'Máquinas',
  'Bandas elásticas',
  'Kettlebell',
  'Solo peso corporal',
];

/// Datos permanentes para generar rutinas con IA (sección 16): se piden
/// una sola vez y se pueden editar cuando cambien.
class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(profileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil de entrenamiento')),
      body: perfil.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            e is ApiException ? e.message : 'No se pudo cargar tu perfil',
            style: const TextStyle(color: AppColors.estadoVencido),
          ),
        ),
        data: (p) => _TrainingForm(inicial: p.entrenamiento),
      ),
    );
  }
}

class _TrainingForm extends ConsumerStatefulWidget {
  final PerfilEntrenamiento? inicial;
  const _TrainingForm({this.inicial});

  @override
  ConsumerState<_TrainingForm> createState() => _TrainingFormState();
}

class _TrainingFormState extends ConsumerState<_TrainingForm> {
  String? _objetivo;
  String? _nivel;
  int? _minutos;
  late Set<String> _diasSel;
  late List<String> _equipamiento;
  late List<String> _lesiones;
  late List<String> _preferencias;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final i = widget.inicial;
    _objetivo = i?.objetivo;
    _nivel = i?.nivel;
    _minutos = i?.minutosPorSesion;
    _diasSel = {...?i?.diasDisponibles};
    _equipamiento = [...?i?.equipamiento];
    _lesiones = [...?i?.lesiones];
    _preferencias = [...?i?.preferencias];
  }

  Future<void> _guardar() async {
    setState(() {
      _guardando = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(memberRepositoryProvider).guardarEntrenamiento(
            PerfilEntrenamiento(
              objetivo: _objetivo,
              nivel: _nivel,
              minutosPorSesion: _minutos,
              // Se conserva el orden de la semana.
              diasDisponibles:
                  _dias.keys.where((d) => _diasSel.contains(d)).toList(),
              equipamiento: _equipamiento,
              lesiones: _lesiones,
              preferencias: _preferencias,
            ),
          );
      ref.invalidate(profileProvider);
      if (!mounted) return;
      messenger.showSnackBar(
          const SnackBar(content: Text('Perfil de entrenamiento guardado')));
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
    final titulo = Theme.of(context).textTheme.titleSmall;
    const separador = SizedBox(height: 24);
    final objetivos = [
      ..._objetivos,
      if (_objetivo != null && !_objetivos.contains(_objetivo)) _objetivo!,
    ];

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Objetivo', style: titulo),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final o in objetivos)
              ChoiceChip(
                label: Text(o),
                selected: _objetivo == o,
                onSelected: (s) => setState(() => _objetivo = s ? o : null),
              ),
          ],
        ),
        separador,
        Text('Nivel', style: titulo),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final e in _niveles.entries)
              ChoiceChip(
                label: Text(e.value),
                selected: _nivel == e.key,
                onSelected: (s) => setState(() => _nivel = s ? e.key : null),
              ),
          ],
        ),
        separador,
        Text('Días en los que puedes entrenar', style: titulo),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final e in _dias.entries)
              FilterChip(
                label: Text(e.value),
                selected: _diasSel.contains(e.key),
                onSelected: (s) => setState(() {
                  if (s) {
                    _diasSel.add(e.key);
                  } else {
                    _diasSel.remove(e.key);
                  }
                }),
              ),
          ],
        ),
        separador,
        Text('Tiempo disponible por sesión', style: titulo),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final m in _duraciones)
              ChoiceChip(
                label: Text('$m min'),
                selected: _minutos == m,
                onSelected: (s) => setState(() => _minutos = s ? m : null),
              ),
          ],
        ),
        separador,
        TagsEditor(
          label: 'Equipamiento disponible',
          hint: 'Escribe o elige uno',
          values: _equipamiento,
          suggestions: _equipos,
          onChanged: (v) => setState(() => _equipamiento = v),
        ),
        separador,
        TagsEditor(
          label: 'Lesiones o limitaciones',
          hint: 'Ej. rodilla derecha',
          values: _lesiones,
          onChanged: (v) => setState(() => _lesiones = v),
        ),
        separador,
        TagsEditor(
          label: 'Preferencias de entrenamiento',
          hint: 'Ej. me gusta el cardio',
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
              : const Text('Guardar perfil'),
        ),
      ],
    );
  }
}
