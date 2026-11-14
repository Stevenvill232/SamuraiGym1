import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import '../../../providers/auth_provider.dart';

/// Restablece la contraseña de un miembro (o de alguien del personal, si
/// quien lo hace es administrador). Útil cuando el miembro la olvidó: no hay
/// recuperación por correo, así que la resuelve el gimnasio.
class ResetPasswordDialog extends ConsumerStatefulWidget {
  final Usuario usuario;
  const ResetPasswordDialog({super.key, required this.usuario});

  @override
  ConsumerState<ResetPasswordDialog> createState() =>
      _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends ConsumerState<ResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl = TextEditingController();
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await ref
          .read(apiClientProvider)
          .patch('/users/${widget.usuario.id}/password',
              body: {'password': _ctrl.text});
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _guardando = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Restablecer contraseña'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nueva contraseña para ${widget.usuario.nombreCompleto}. '
                  'Compártesela por un medio seguro y pídele que la cambie '
                  'desde su perfil.'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ctrl,
                decoration: const InputDecoration(labelText: 'Nueva contraseña'),
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(color: AppColors.estadoVencido)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardando ? null : _guardar,
          child: const Text('Restablecer'),
        ),
      ],
    );
  }
}
