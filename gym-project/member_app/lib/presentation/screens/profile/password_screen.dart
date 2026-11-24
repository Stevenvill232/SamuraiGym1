import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import '../../../providers/member_providers.dart';

class PasswordScreen extends ConsumerWidget {
  const PasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar contraseña')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: PasswordForm(
          onSubmit: (actual, nueva) async {
            try {
              await ref
                  .read(memberRepositoryProvider)
                  .cambiarPassword(actual, nueva);
              return null;
            } on ApiException catch (e) {
              return e.message;
            }
          },
        ),
      ),
    );
  }
}
