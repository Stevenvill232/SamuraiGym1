import 'package:flutter/material.dart';
import '../../widgets/module_placeholder.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholder(
      title: 'Configuración',
      description:
          'Ajustes generales del gimnasio, precios y permisos (sin afectar histórico).',
      icon: Icons.settings_rounded,
      proximamente: [
        'Precios de planes y tiqueteras editables sin migrar código',
        'Categorías de gastos y métodos de pago',
        'Horarios de Boxeo, Karate y MMA',
        'Stock mínimo predeterminado y notificaciones',
        'Gestión de roles adicionales (Recepción, Entrenador, Contador)',
      ],
    );
  }
}
