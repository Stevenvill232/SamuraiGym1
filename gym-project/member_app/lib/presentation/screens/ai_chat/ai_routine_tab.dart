import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import '../../../providers/member_providers.dart';
import 'ai_widgets.dart';

const _enfoques = [
  'Cuerpo completo',
  'Pecho y tríceps',
  'Espalda y bíceps',
  'Piernas y glúteos',
  'Hombros y core',
  'Cardio',
];

/// Genera una rutina personalizada con IA y guarda el historial.
class AiRoutineTab extends ConsumerStatefulWidget {
  const AiRoutineTab({super.key});

  @override
  ConsumerState<AiRoutineTab> createState() => _AiRoutineTabState();
}

class _AiRoutineTabState extends ConsumerState<AiRoutineTab>
    with AutomaticKeepAliveClientMixin {
  String _enfoque = _enfoques.first;
  String _lugar = 'GIMNASIO';
  String _intensidad = 'MEDIA';
  int _minutos = 45;
  bool _generando = false;
  bool _recien = false;
  String? _error;
  final _notasCtrl = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _generar() async {
    setState(() {
      _generando = true;
      _error = null;
    });
    try {
      await ref.read(memberRepositoryProvider).generarRutina(
            enfoque: _enfoque,
            lugar: _lugar,
            intensidad: _intensidad,
            minutos: _minutos,
            notas: _notasCtrl.text.trim(),
          );
      ref.invalidate(rutinasProvider);
      ref.invalidate(memberDashboardProvider);
      if (mounted) setState(() => _recien = true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final perfil = ref.watch(profileProvider).valueOrNull;
    final rutinas = ref.watch(rutinasProvider);
    final muted = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: AppColors.textMuted);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (perfil != null && perfil.entrenamiento == null)
          const PerfilIncompletoBanner(
            texto:
                'Completa tu perfil de entrenamiento (nivel, lesiones, equipamiento) para rutinas más precisas.',
            ruta: '/profile/training',
          ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ChipsSeleccion<String>(
                  titulo: 'Hoy quiero entrenar',
                  opciones: [for (final e in _enfoques) (e, e)],
                  valor: _enfoque,
                  onChanged: (v) => setState(() => _enfoque = v),
                ),
                ChipsSeleccion<String>(
                  titulo: 'Lugar',
                  opciones: const [('Gimnasio', 'GIMNASIO'), ('Casa', 'CASA')],
                  valor: _lugar,
                  onChanged: (v) => setState(() => _lugar = v),
                ),
                ChipsSeleccion<String>(
                  titulo: 'Intensidad',
                  opciones: const [
                    ('Suave', 'SUAVE'),
                    ('Media', 'MEDIA'),
                    ('Alta', 'ALTA'),
                  ],
                  valor: _intensidad,
                  onChanged: (v) => setState(() => _intensidad = v),
                ),
                ChipsSeleccion<int>(
                  titulo: 'Tiempo disponible',
                  opciones: const [
                    ('30 min', 30),
                    ('45 min', 45),
                    ('60 min', 60),
                    ('90 min', 90),
                  ],
                  valor: _minutos,
                  onChanged: (v) => setState(() => _minutos = v),
                ),
                TextField(
                  controller: _notasCtrl,
                  maxLength: 300,
                  decoration: const InputDecoration(
                    labelText: 'Algo más (opcional)',
                    hintText: 'Ej. hoy me duele un poco el hombro',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _generando ? null : _generar,
          icon: const Icon(Icons.auto_awesome_rounded),
          label: Text(_generando ? 'Armando tu rutina...' : 'Generar mi rutina'),
        ),
        if (_generando)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LinearProgressIndicator(),
                const SizedBox(height: 6),
                Text('Puede tardar unos segundos...', style: muted),
              ],
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_error!,
                style: const TextStyle(color: AppColors.estadoVencido)),
          ),
        const SizedBox(height: 24),
        Text('Mis rutinas', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        ...rutinas.when<List<Widget>>(
          loading: () => const [
            Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
          error: (e, _) => [
            Text(e is ApiException ? e.message : 'No se pudo cargar el historial',
                style: const TextStyle(color: AppColors.estadoVencido)),
          ],
          data: (lista) {
            if (lista.isEmpty) {
              return [
                Text('Aún no has generado rutinas. ¡Crea la primera!',
                    style: muted),
              ];
            }
            return [
              for (var i = 0; i < lista.length; i++)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ExpansionTile(
                    key: ValueKey(lista[i].id),
                    initiallyExpanded: i == 0 && _recien,
                    shape: const Border(),
                    title: Text(lista[i].titulo,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        '${cuandoCorto(lista[i].fecha)} · intensidad ${etiquetaIntensidad(lista[i].intensidad)}'),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [RutinaView(rutina: lista[i])],
                  ),
                ),
            ];
          },
        ),
      ],
    );
  }
}
