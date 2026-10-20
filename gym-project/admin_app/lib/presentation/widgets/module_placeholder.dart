import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

/// Placeholder intencional (no una pantalla en blanco) para los módulos que
/// se construirán en los próximos pasos. Deja claro qué va a tener el
/// módulo, para que sirva de checklist visual mientras se desarrolla.
class ModulePlaceholder extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final List<String> proximamente;

  const ModulePlaceholder({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.proximamente = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(description,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: AppColors.ember, size: 22),
                      const SizedBox(width: 10),
                      Text('En construcción',
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (proximamente.isNotEmpty) ...[
                    Text('Este módulo incluirá:',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    for (final item in proximamente)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline_rounded,
                                size: 16, color: AppColors.textMuted),
                            const SizedBox(width: 8),
                            Text(item,
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
