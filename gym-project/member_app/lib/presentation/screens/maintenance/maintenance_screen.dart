import 'package:flutter/material.dart';
import '../../widgets/module_placeholder.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholder(
      title: 'Progreso',
      description: 'Evolución de tu peso y estatura a lo largo del tiempo.',
      icon: Icons.monitor_weight_rounded,
      proximamente: [
        'Registro periódico de peso y estatura',
        'Gráfico de evolución (fl_chart) con fecha en el eje X',
        'Comparación contra tu objetivo definido en Perfil',
        'Estos datos alimentan las rutinas y recomendaciones de IA',
      ],
    );
  }
}
