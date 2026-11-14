import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import '../../../providers/auth_provider.dart';

const _roles = ['RECEPCION', 'ENTRENADOR', 'CONTADOR', 'ADMINISTRADOR'];

String etiquetaRolApi(String r) => switch (r) {
      'ADMINISTRADOR' => 'Administrador',
      'RECEPCION' => 'Recepción',
      'ENTRENADOR' => 'Entrenador',
      'CONTADOR' => 'Contador',
      _ => r,
    };

/// Crear o editar una persona del personal (no miembros).
class StaffFormDialog extends ConsumerStatefulWidget {
  final Usuario? usuario;
  const StaffFormDialog({super.key, this.usuario});

  @override
  ConsumerState<StaffFormDialog> createState() => _StaffFormDialogState();
}

class _StaffFormDialogState extends ConsumerState<StaffFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _cedulaCtrl;
  late final TextEditingController _nombresCtrl;
  late final TextEditingController _apellidosCtrl;
  late final TextEditingController _celularCtrl;
  final _passwordCtrl = TextEditingController();
  late String _rol;
  bool _guardando = false;
  String? _error;

  bool get _esEdicion => widget.usuario != null;

  @override
  void initState() {
    super.initState();
    final u = widget.usuario;
    _cedulaCtrl = TextEditingController(text: u?.cedula ?? '');
    _nombresCtrl = TextEditingController(text: u?.nombres ?? '');
    _apellidosCtrl = TextEditingController(text: u?.apellidos ?? '');
    _celularCtrl = TextEditingController(text: u?.celular ?? '');
    final actual = u?.role.toApi() ?? 'RECEPCION';
    _rol = _roles.contains(actual) ? actual : 'RECEPCION';
  }

  @override
  void dispose() {
    _cedulaCtrl.dispose();
    _nombresCtrl.dispose();
    _apellidosCtrl.dispose();
    _celularCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    final api = ref.read(apiClientProvider);
    final celular = _celularCtrl.text.trim();
    try {
      if (_esEdicion) {
        await api.patch('/users/${widget.usuario!.id}', body: {
          'nombres': _nombresCtrl.text.trim(),
          'apellidos': _apellidosCtrl.text.trim(),
          if (celular.isNotEmpty) 'celular': celular,
          'role': _rol,
        });
      } else {
        await api.post('/users', body: {
          'cedula': _cedulaCtrl.text.trim(),
          'nombres': _nombresCtrl.text.trim(),
          'apellidos': _apellidosCtrl.text.trim(),
          'password': _passwordCtrl.text,
          if (celular.isNotEmpty) 'celular': celular,
          'role': _rol,
        });
      }
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
      title: Text(_esEdicion ? 'Editar personal' : 'Nuevo personal'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _cedulaCtrl,
                  enabled: !_esEdicion,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cédula'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nombresCtrl,
                        decoration: const InputDecoration(labelText: 'Nombres'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _apellidosCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Apellidos'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _celularCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Celular'),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _rol,
                  decoration: const InputDecoration(labelText: 'Rol'),
                  items: _roles
                      .map((r) => DropdownMenuItem(
                          value: r, child: Text(etiquetaRolApi(r))))
                      .toList(),
                  onChanged: (v) => setState(() => _rol = v!),
                ),
                if (!_esEdicion) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'Contraseña inicial'),
                    validator: (v) => (v == null || v.length < 6)
                        ? 'Mínimo 6 caracteres'
                        : null,
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      style: const TextStyle(color: AppColors.estadoVencido)),
                ],
              ],
            ),
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
          child: Text(_esEdicion ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }
}
