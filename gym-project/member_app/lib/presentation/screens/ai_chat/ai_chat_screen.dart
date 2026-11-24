import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import '../../../providers/member_providers.dart';
import 'ai_nutrition_tab.dart';
import 'ai_routine_tab.dart';

/// Asistente de IA: chat libre, rutina del día y sugerencias de comida.
class AiChatScreen extends StatelessWidget {
  const AiChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Asistente IA',
                  style: Theme.of(context).textTheme.headlineSmall),
            ),
          ),
          const TabBar(
            labelColor: AppColors.ember,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.ember,
            tabs: [Tab(text: 'Chat'), Tab(text: 'Rutina'), Tab(text: 'Comida')],
          ),
          const Expanded(
            child: TabBarView(
              children: [_ChatTab(), AiRoutineTab(), AiNutritionTab()],
            ),
          ),
        ],
      ),
    );
  }
}

class _Msg {
  final String texto;
  final bool esUsuario;
  final bool error;
  const _Msg(this.texto, this.esUsuario, {this.error = false});
}

class _ChatTab extends ConsumerStatefulWidget {
  const _ChatTab();

  @override
  ConsumerState<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends ConsumerState<_ChatTab>
    with AutomaticKeepAliveClientMixin {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _mensajes = [];
  bool _enviando = false;

  static const _sugerencias = [
    '¿Qué ejercicios hago hoy?',
    'Ideas de almuerzo saludable',
    '¿Cómo mejoro mi técnica en sentadilla?',
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _bajar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _enviar([String? textoDirecto]) async {
    final texto = (textoDirecto ?? _ctrl.text).trim();
    if (texto.isEmpty || _enviando) return;

    // Contexto de la conversación (sin mensajes de error), máximo 10 turnos.
    final historial = [
      for (final m in _mensajes)
        if (!m.error)
          (rol: m.esUsuario ? 'usuario' : 'asistente', texto: m.texto),
    ];
    final recorte =
        historial.length > 10 ? historial.sublist(historial.length - 10) : historial;

    setState(() {
      _mensajes.add(_Msg(texto, true));
      _enviando = true;
      _ctrl.clear();
    });
    _bajar();

    try {
      final r = await ref.read(memberRepositoryProvider).chat(texto, recorte);
      if (!mounted) return;
      setState(() => _mensajes.add(_Msg(r, false)));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _mensajes.add(_Msg(e.message, false, error: true)));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
    _bajar();
  }

  Widget _burbuja(_Msg m) {
    final ancho = MediaQuery.of(context).size.width * 0.8;
    return Align(
      alignment: m.esUsuario ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: ancho),
        decoration: BoxDecoration(
          color: m.esUsuario
              ? AppColors.ember
              : (m.error
                  ? AppColors.estadoVencido.withValues(alpha: 0.08)
                  : AppColors.surface),
          border: m.esUsuario
              ? null
              : Border.all(
                  color: m.error ? AppColors.estadoVencido : AppColors.borderSubtle),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          m.texto,
          style: TextStyle(
            color: m.esUsuario
                ? Colors.white
                : (m.error ? AppColors.estadoVencido : AppColors.textPrimary),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final muted = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: AppColors.textMuted);

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.all(20),
            children: [
              _burbuja(const _Msg(
                '¡Hola! Soy tu asistente de entrenamiento y alimentación. '
                'Conozco tu perfil y tus medidas, así que puedo darte consejos pensados para ti. ¿En qué te ayudo?',
                false,
              )),
              if (_mensajes.isEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final s in _sugerencias)
                      ActionChip(label: Text(s), onPressed: () => _enviar(s)),
                  ],
                ),
              for (final m in _mensajes) _burbuja(m),
              if (_enviando)
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 4),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text('Escribiendo...', style: muted),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'No reemplaza la evaluación de un profesional de la salud.',
                style: muted?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    maxLength: 800,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _enviar(),
                    decoration: const InputDecoration(
                      hintText: 'Escribe tu pregunta...',
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _enviando ? null : () => _enviar(),
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
