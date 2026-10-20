import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(description,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
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
                  const SizedBox(height: 14),
                  for (final item in proximamente)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 3),
                            child: Icon(Icons.check_circle_outline_rounded,
                                size: 16, color: AppColors.textMuted),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(item,
                                style: Theme.of(context).textTheme.bodyMedium),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
