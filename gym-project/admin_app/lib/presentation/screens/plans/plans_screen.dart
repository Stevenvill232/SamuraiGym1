import 'package:flutter/material.dart';
import '../../widgets/module_placeholder.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholder(
      title: 'Planes y Pagos',
      description:
          'Gimnasio (sesión/quincena/mes), tiqueteras y Boxeo/Karate/MMA.',
      icon: Icons.card_membership_rounded,
      proximamente: [
        'Venta de planes de gimnasio y registro de método de pago',
        'Gestión de tiqueteras: días disponibles + vigencia + uso',
        'Botón "Registrar día utilizado" con validaciones',
        'Planes de Boxeo, Karate y MMA con horarios asignados',
        'Historial de planes por miembro (sin borrado físico)',
      ],
    );
  }
}
