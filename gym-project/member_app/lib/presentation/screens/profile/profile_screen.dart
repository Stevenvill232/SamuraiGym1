import 'package:flutter/material.dart';
import '../../widgets/module_placeholder.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholder(
      title: 'Perfil',
      description: 'Tus datos personales y preferencias de alimentación.',
      icon: Icons.person_rounded,
      proximamente: [
        'Foto, nombres, celular, correo y dirección editables',
        'Cédula NO editable desde la app (regla de negocio)',
        'Edad calculada automáticamente desde la fecha de nacimiento',
        'Preferencias de alimentación (una sola vez): objetivo, dieta, '
            'alergias y alimentos que no consume',
        'Cambio de contraseña',
      ],
    );
  }
}
