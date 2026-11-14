import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Formulario de cambio de contraseña, compartido por ambas apps.
/// [onSubmit] devuelve `null` si todo salió bien o el mensaje de error.
class PasswordForm extends StatefulWidget {
  final Future<String?> Function(String actual, String nueva) onSubmit;
  const PasswordForm({super.key, required this.onSubmit});

  @override
  State<PasswordForm> createState() => _PasswordFormState();
}

class _PasswordFormState extends State<PasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _actualCtrl = TextEditingController();
  final _nuevaCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();
  bool _ocultar = true;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _actualCtrl.dispose();
    _nuevaCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    final error = await widget.onSubmit(_actualCtrl.text, _nuevaCtrl.text);
    if (!mounted) return;
    setState(() {
      _guardando = false;
      _error = error;
    });
    if (error == null) {
      _actualCtrl.clear();
      _nuevaCtrl.clear();
      _confirmarCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada correctamente')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _actualCtrl,
            obscureText: _ocultar,
            decoration: InputDecoration(
              labelText: 'Contraseña actual',
              suffixIcon: IconButton(
                icon: Icon(_ocultar
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded),
                onPressed: () => setState(() => _ocultar = !_ocultar),
              ),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Ingresa tu contraseña actual' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _nuevaCtrl,
            obscureText: _ocultar,
            decoration: const InputDecoration(labelText: 'Nueva contraseña'),
            validator: (v) =>
                (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _confirmarCtrl,
            obscureText: _ocultar,
            decoration:
                const InputDecoration(labelText: 'Confirmar nueva contraseña'),
            validator: (v) =>
                v != _nuevaCtrl.text ? 'Las contraseñas no coinciden' : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(_error!, style: const TextStyle(color: AppColors.estadoVencido)),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _guardando ? null : _guardar,
            child: _guardando
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Cambiar contraseña'),
          ),
        ],
      ),
    );
  }
}
