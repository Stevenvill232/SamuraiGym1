import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

class _ChatMessage {
  final String texto;
  final bool esUsuario;
  const _ChatMessage(this.texto, this.esUsuario);
}

/// UI funcional del chat (estado local); el envío real a
/// POST /api/ai/chat se conecta en la Fase 7, cuando exista el AiModule en
/// el backend. El backend debe recibir el contexto del miembro (ver
/// ARQUITECTURA.md -> Flujo de IA) y responder con la respuesta generada.
class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _mensajes = [
    const _ChatMessage(
      '¡Hola! Soy tu asistente de entrenamiento y alimentación. '
      'Pregúntame lo que necesites, por ejemplo: "¿qué ejercicios puedo '
      'hacer hoy para pecho?"',
      false,
    ),
  ];
  bool _enviando = false;

  void _enviar() {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;

    setState(() {
      _mensajes.add(_ChatMessage(texto, true));
      _enviando = true;
      _controller.clear();
    });

    // TODO(Fase 7): reemplazar por la llamada real al backend
    // (POST /api/ai/chat) y quitar este eco de ejemplo.
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _mensajes.add(const _ChatMessage(
          'Esta es una respuesta de ejemplo. Cuando conectemos la IA en el '
          'backend, aquí verás la recomendación real basada en tu perfil.',
          false,
        ));
        _enviando = false;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Row(
            children: [
              Text('Asistente IA',
                  style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Text(
                '⚠ No reemplaza la evaluación de un profesional de la salud.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(24),
            itemCount: _mensajes.length,
            itemBuilder: (context, index) {
              final m = _mensajes[index];
              return Align(
                alignment: m.esUsuario
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75),
                  decoration: BoxDecoration(
                    color: m.esUsuario ? AppColors.ember : AppColors.surface,
                    border: m.esUsuario
                        ? null
                        : Border.all(color: AppColors.borderSubtle),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    m.texto,
                    style: TextStyle(
                      color: m.esUsuario ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Escribe tu pregunta...',
                    ),
                    onSubmitted: (_) => _enviar(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _enviando ? null : _enviar,
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
