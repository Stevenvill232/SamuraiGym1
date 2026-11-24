import 'package:flutter/material.dart';

/// Editor de listas de textos cortos (alergias, lesiones, categorías...).
/// El estado vive en quien lo usa: recibe [values] y avisa con [onChanged].
class TagsEditor extends StatefulWidget {
  final String label;
  final String? hint;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final List<String> suggestions;
  final int maxItems;

  const TagsEditor({
    super.key,
    required this.label,
    required this.values,
    required this.onChanged,
    this.hint,
    this.suggestions = const [],
    this.maxItems = 30,
  });

  @override
  State<TagsEditor> createState() => _TagsEditorState();
}

class _TagsEditorState extends State<TagsEditor> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool _existe(String t) =>
      widget.values.any((v) => v.toLowerCase() == t.toLowerCase());

  void _agregar(String texto) {
    final t = texto.trim();
    if (t.isEmpty) return;
    if (!_existe(t) && widget.values.length < widget.maxItems) {
      widget.onChanged([...widget.values, t]);
    }
    _ctrl.clear();
  }

  void _quitar(String v) =>
      widget.onChanged(widget.values.where((e) => e != v).toList());

  @override
  Widget build(BuildContext context) {
    final sugerencias =
        widget.suggestions.where((s) => !_existe(s)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (widget.values.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final v in widget.values)
                InputChip(label: Text(v), onDeleted: () => _quitar(v)),
            ],
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                decoration: InputDecoration(
                  hintText: widget.hint ?? 'Escribe y pulsa Enter para agregar',
                  isDense: true,
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: _agregar,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: () => _agregar(_ctrl.text),
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        if (sugerencias.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final s in sugerencias)
                  ActionChip(label: Text(s), onPressed: () => _agregar(s)),
              ],
            ),
          ),
      ],
    );
  }
}
