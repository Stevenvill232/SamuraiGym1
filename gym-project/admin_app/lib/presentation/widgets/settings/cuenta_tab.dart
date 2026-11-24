import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import '../../../providers/auth_provider.dart';
import 'settings_common.dart';

/// Datos de la propia cuenta (disponible para todos los roles): correo de
/// recuperación y cambio de contraseña.
class CuentaTab extends ConsumerWidget {
  const CuentaTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TabScroll(
      children: [
        const _CorreoCard(),
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

/// Correo al que se envía el código si olvidas tu contraseña. Sin correo
/// registrado, la recuperación no puede funcionar.
class _CorreoCard extends ConsumerStatefulWidget {
  const _CorreoCard();

  @override
  ConsumerState<_CorreoCard> createState() => _CorreoCardState();
}

class _CorreoCardState extends ConsumerState<_CorreoCard> {
  final _ctrl = TextEditingController();
  bool _cargando = true;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    String correo = '';
    String? error;
    try {
      final p = await ref.read(apiClientProvider).get('/profile');
      correo = (p['correo'] as String?) ?? '';
    } on ApiException catch (e) {
      error = e.message;
    }
    // Si el usuario ya cambió de pestaña, este widget fue destruido: no se
    // debe tocar el controlador (ya fue liberado).
    if (!mounted) return;
    setState(() {
      _ctrl.text = correo;
      _error = error;
      _cargando = false;
    });
  }

  Future<void> _guardar() async {
    final t = _ctrl.text.trim();
    if (t.isNotEmpty && !(t.contains('@') && t.contains('.'))) {
      setState(() => _error = 'Correo inválido');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await ref
          .read(apiClientProvider)
          .patch('/profile', body: {'correo': t.isEmpty ? null : t});
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Correo guardado')));
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
    return SeccionCard(
      titulo: 'Correo de recuperación',
      descripcion:
          'Si olvidas tu contraseña, te enviaremos un código a este correo desde la pantalla de ingreso.',
      child: _cargando
          ? const LinearProgressIndicator()
          : SizedBox(
              width: 420,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _ctrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration:
                        const InputDecoration(labelText: 'Correo electrónico'),
                  ),
                  const SizedBox(height: 14),
                  BotonGuardar(
                    guardando: _guardando,
                    error: _error,
                    onPressed: _guardar,
                    texto: 'Guardar correo',
                  ),
                ],
              ),
            ),
    );
  }
}
