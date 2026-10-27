import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

class MemberListTile extends StatelessWidget {
  final Usuario miembro;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onVerPlanes;

  const MemberListTile({
    super.key,
    required this.miembro,
    required this.onEdit,
    required this.onDelete,
    required this.onVerPlanes,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: AppColors.background,
          backgroundImage:
              miembro.foto != null ? NetworkImage(miembro.foto!) : null,
          child: miembro.foto == null
              ? Text(
                  miembro.nombres.isNotEmpty ? miembro.nombres[0] : '?',
                  style: const TextStyle(color: AppColors.textMuted),
                )
              : null,
        ),
        title: Text(miembro.nombreCompleto,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          'CC ${miembro.cedula}'
          '${miembro.edad != null ? ' · ${miembro.edad} años' : ''}'
          '${miembro.celular != null && miembro.celular!.isNotEmpty ? ' · ${miembro.celular}' : ''}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Ver planes',
              icon: const Icon(Icons.card_membership_outlined),
              onPressed: onVerPlanes,
            ),
            IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: 'Desactivar',
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.estadoVencido),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
