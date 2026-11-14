import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import '../../../providers/auth_provider.dart';
import 'settings_common.dart';

/// Cambio de contraseña del usuario logueado (disponible para todos los roles).
class CuentaTab extends ConsumerWidget {
  const CuentaTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TabScroll(
      children: [
        SeccionCard(
          titulo: 'Cambiar mi contraseña',
          descripcion: 'Usa una contraseña que no uses en otros sitios.',
          child: SizedBox(
            width: 420,
            child: PasswordForm(
              onSubmit: (actual, nueva) async {
                try {
                  await ref.read(apiClientProvider).patch('/auth/password',
                      body: {'actual': actual, 'nueva': nueva});
                  return null;
                } on ApiException catch (e) {
                  return e.message;
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
