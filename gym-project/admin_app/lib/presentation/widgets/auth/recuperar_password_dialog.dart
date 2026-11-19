import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import '../../../providers/auth_provider.dart';

/// Recuperación de contraseña del personal, en 2 pasos:
///  1) cédula -> el sistema envía un código de 6 dígitos al correo registrado
///  2) código + nueva contraseña
/// Devuelve `true` si la contraseña se cambió.
class RecuperarPasswordDialog extends ConsumerStatefulWidget {
  final String cedulaInicial;
  const RecuperarPasswordDialog({super.key, this.cedulaInicial = ''});

  @override
  ConsumerState<RecuperarPasswordDialog> createState() =>
      _RecuperarPasswordDialogState();
}

class _RecuperarPasswordDialogState
    extends ConsumerState<RecuperarPasswordDialog> {
  late final TextEditingController _cedulaCtrl;
  final _codigoCtrl = TextEditingController();
  final _nuevaCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();

  int _paso = 0;
  bool _cargando = false;
  bool _ocultar = true;
  String? _error;
  String? _info;
  int _espera = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _cedulaCtrl = TextEditingController(text: widget.cedulaInicial);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cedulaCtrl.dispose();
    _codigoCtrl.dispose();
    _nuevaCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  void _iniciarEspera() {
    _timer?.cancel();
    setState(() => _espera = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _espera--);
      if (_espera <= 0) t.cancel();
    });
  }

  Future<void> _solicitar() async {
    final cedula = _cedulaCtrl.text.trim();
    if (cedula.length < 3) {
      setState(() => _error = 'Ingresa tu cédula');
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final data = await ref
          .read(apiClientProvider)
          .post('/auth/password-reset/request', body: {'cedula': cedula});
      if (!mounted) return;
      setState(() {
        _paso = 1;
        _cargando = false;
        _info = data['message'] as String?;
        _codigoCtrl.clear();
      });
      _iniciarEspera();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _cargando = false;
          _error = e.message;
        });
      }
    }
  }

  Future<void> _confirmar() async {
    if (_codigoCtrl.text.trim().length != 6) {
      setState(() => _error = 'El código tiene 6 dígitos');
      return;
    }
    if (_nuevaCtrl.text.length < 6) {
      setState(() => _error = 'La contraseña debe tener mínimo 6 caracteres');
      return;
    }
    if (_nuevaCtrl.text != _confirmarCtrl.text) {
      setState(() => _error = 'Las contraseñas no coinciden');
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await ref.read(apiClientProvider).post('/auth/password-reset/confirm',
          body: {
            'cedula': _cedulaCtrl.text.trim(),
            'codigo': _codigoCtrl.text.trim(),
            'nueva': _nuevaCtrl.text,
          });
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _cargando = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: AppColors.textMuted);

    return AlertDialog(
      title: const Text('Recuperar contraseña'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_paso == 0) ...[
                Text(
                  'Ingresa tu cédula. Si tienes un correo registrado en el sistema, te enviaremos un código de 6 dígitos para crear una contraseña nueva.',
                  style: muted,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _cedulaCtrl,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Cédula'),
                  onSubmitted: (_) => _solicitar(),
                ),
              ] else ...[
                Text(_info ?? 'Revisa tu correo.', style: muted),
                const SizedBox(height: 16),
                TextField(
                  controller: _codigoCtrl,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                      labelText: 'Código de 6 dígitos', counterText: ''),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nuevaCtrl,
                  obscureText: _ocultar,
                  decoration: InputDecoration(
                    labelText: 'Nueva contraseña',
                    suffixIcon: IconButton(
                      icon: Icon(_ocultar
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded),
                      onPressed: () => setState(() => _ocultar = !_ocultar),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmarCtrl,
                  obscureText: _ocultar,
                  decoration: const InputDecoration(
                      labelText: 'Confirmar nueva contraseña'),
                  onSubmitted: (_) => _confirmar(),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: (_espera > 0 || _cargando) ? null : _solicitar,
                  child: Text(_espera > 0
                      ? 'Reenviar código en ${_espera}s'
                      : 'Reenviar código'),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    style: const TextStyle(color: AppColors.estadoVencido)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _cargando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _cargando ? null : (_paso == 0 ? _solicitar : _confirmar),
          child: _cargando
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(_paso == 0 ? 'Enviar código' : 'Cambiar contraseña'),
        ),
      ],
    );
  }
}
