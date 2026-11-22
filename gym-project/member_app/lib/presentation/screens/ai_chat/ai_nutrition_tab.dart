import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import '../../../providers/member_providers.dart';
import 'ai_widgets.dart';

/// Sugiere comidas personalizadas con IA (respeta alergias y restricciones).
class AiNutritionTab extends ConsumerStatefulWidget {
  const AiNutritionTab({super.key});

  @override
  ConsumerState<AiNutritionTab> createState() => _AiNutritionTabState();
}

class _AiNutritionTabState extends ConsumerState<AiNutritionTab>
    with AutomaticKeepAliveClientMixin {
  late String _tipo;
  bool _generando = false;
  bool _recien = false;
  String? _error;
  final _notasCtrl = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Propone el tipo de comida según la hora del día.
    final h = DateTime.now().hour;
    _tipo = h < 10
        ? 'DESAYUNO'
        : h < 12
            ? 'MEDIA_MANANA'
            : h < 15
                ? 'ALMUERZO'
                : h < 18
                    ? 'MERIENDA'
                    : 'CENA';
  }

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
      await ref
          .read(memberRepositoryProvider)
          .generarComida(_tipo, notas: _notasCtrl.text.trim());
      ref.invalidate(comidasProvider);
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
    final comidas = ref.watch(comidasProvider);
    final muted = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: AppColors.textMuted);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (perfil != null && perfil.alimentacion == null)
          const PerfilIncompletoBanner(
            texto:
                'Completa tus preferencias de alimentación (alergias, alimentos que no consumes) para sugerencias seguras.',
            ruta: '/profile/nutrition',
          ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ChipsSeleccion<String>(
                  titulo: '¿Para qué comida?',
                  opciones: const [
                    ('Desayuno', 'DESAYUNO'),
                    ('Media mañana', 'MEDIA_MANANA'),
                    ('Almuerzo', 'ALMUERZO'),
                    ('Merienda', 'MERIENDA'),
                    ('Cena', 'CENA'),
                  ],
                  valor: _tipo,
                  onChanged: (v) => setState(() => _tipo = v),
                ),
                TextField(
                  controller: _notasCtrl,
                  maxLength: 300,
                  decoration: const InputDecoration(
                    labelText: 'Algo más (opcional)',
                    hintText: 'Ej. tengo huevos y arroz en casa',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _generando ? null : _generar,
          icon: const Icon(Icons.restaurant_rounded),
          label: Text(_generando ? 'Pensando tu comida...' : 'Sugerir comida'),
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
        Text('Mis sugerencias', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        ...comidas.when<List<Widget>>(
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
                Text('Aún no tienes sugerencias. ¡Pide la primera!', style: muted),
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
                        '${etiquetaTipoComida(lista[i].tipoComida)} · ${cuandoCorto(lista[i].fecha)}'),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [ComidaView(comida: lista[i])],
                  ),
                ),
            ];
          },
        ),
      ],
    );
  }
}
