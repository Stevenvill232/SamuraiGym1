import 'package:flutter/material.dart';
import '../../widgets/module_placeholder.dart';

class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholder(
      title: 'Miembros',
      description: 'Búsqueda, registro y gestión de miembros del gimnasio.',
      icon: Icons.groups_rounded,
      proximamente: [
        'Barra de búsqueda por cédula, nombre o celular',
        'Formulario de registro de nuevo miembro (con edad calculada)',
        'Listado con foto, estado y acciones (ver / editar / eliminar)',
        'Confirmación y desactivación lógica al eliminar',
      ],
    );
  }
}
