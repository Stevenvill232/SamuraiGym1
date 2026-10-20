import 'package:flutter/material.dart';
import '../../widgets/module_placeholder.dart';

class PlanLineScreen extends StatelessWidget {
  const PlanLineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholder(
      title: 'Mi plan',
      description: 'Detalle de tu plan actual, tiquetera e historial.',
      icon: Icons.timeline_rounded,
      proximamente: [
        'Tipo de plan, fecha de inicio y de vencimiento',
        'Días restantes / usados si es tiquetera',
        'Estado visual (activo, por vencer, vencido, agotado)',
        'Historial de planes anteriores',
        'Acceso rápido a renovación (te contacta con recepción)',
      ],
    );
  }
}
