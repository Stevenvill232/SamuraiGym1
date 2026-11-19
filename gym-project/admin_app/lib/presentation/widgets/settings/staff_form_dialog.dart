import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import '../../../providers/auth_provider.dart';

const _rolesPersonal = ['RECEPCION', 'ENTRENADOR', 'CONTADOR', 'ADMINISTRADOR'];

String etiquetaRolApi(String r) => switch (r) {
      'ADMINISTRADOR' => 'Administrador',
      'RECEPCION' => 'Recepción',
      'ENTRENADOR' => 'Entrenador',
      'CONTADOR' => 'Contador',
      _ => r,
    };

/// Crear o editar una persona del personal.
///
/// Una misma persona puede ser personal Y miembro (ej. recepcionista que
/// además paga clases de boxeo): si la cédula ya está registrada, NO se
/// rechaza; se le suma el rol a su cuenta existente.
///
/// Devuelve (al cerrar) el mensaje a mostrar, o null si se canceló.
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
  late final TextEditingController _correoCtrl;
  final _passwordCtrl = TextEditingController();
  String _rol = 'RECEPCION'; // al crear: un rol
  late Set<String> _rolesSel; // al editar: uno o varios
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
    _correoCtrl = TextEditingController(text: u?.correo ?? '');
    _rolesSel = {
      for (final r in u?.rolesPersonal ?? <UserRole>[])
        if (_rolesPersonal.contains(r.toApi())) r.toApi(),
    };
    if (_rolesSel.isEmpty) _rolesSel = {'RECEPCION'};
  }

  @override
  void dispose() {
    _cedulaCtrl.dispose();
    _nombresCtrl.dispose();
    _apellidosCtrl.dispose();
    _celularCtrl.dispose();
    _correoCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_esEdicion && _rolesSel.isEmpty) {
      setState(() => _error = 'Selecciona al menos un rol');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    final api = ref.read(apiClientProvider);
    final celular = _celularCtrl.text.trim();
    final correo = _correoCtrl.text.trim();
    try {
      String mensaje;
      if (_esEdicion) {
        await api.patch('/users/${widget.usuario!.id}', body: {
          'nombres': _nombresCtrl.text.trim(),
          'apellidos': _apellidosCtrl.text.trim(),
          if (celular.isNotEmpty) 'celular': celular,
          if (correo.isNotEmpty) 'correo': correo,
        });
        await api.put('/users/${widget.usuario!.id}/staff-roles',
            body: {'roles': _rolesPersonal.where(_rolesSel.contains).toList()});
        mensaje = 'Datos actualizados correctamente';
      } else {
        final data = await api.post('/users', body: {
          'cedula': _cedulaCtrl.text.trim(),
          'nombres': _nombresCtrl.text.trim(),
          'apellidos': _apellidosCtrl.text.trim(),
          'password': _passwordCtrl.text,
          if (celular.isNotEmpty) 'celular': celular,
          if (correo.isNotEmpty) 'correo': correo,
          'role': _rol,
        });
        if (data['reactivado'] == true) {
          mensaje =
              'Esta persona estaba desactivada: se reactivó como ${etiquetaRolApi(_rol)} con los datos nuevos.';
        } else if (data['yaExistia'] == true) {
          mensaje =
              'Esta persona ya estaba registrada. Se le agregó el rol de ${etiquetaRolApi(_rol)} a su cuenta y conserva su contraseña actual.';
        } else {
          mensaje = 'Personal creado correctamente';
        }
      }
      if (mounted) Navigator.of(context).pop(mensaje);
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
        width: 460,
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
                  decoration: InputDecoration(
                    labelText: 'Cédula',
                    helperMaxLines: 3,
                    helperText: _esEdicion
                        ? null
                        : 'Si la persona ya está registrada (por ejemplo como miembro), se le agrega este rol a su cuenta y conserva su contraseña.',
                  ),
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
                  controller: _correoCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    helperText: 'Se usa para recuperar la contraseña',
                  ),
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty) return null;
                    return (t.contains('@') && t.contains('.'))
                        ? null
                        : 'Correo inválido';
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _celularCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Celular'),
                ),
                const SizedBox(height: 16),
                if (_esEdicion) ...[
                  Text('Roles de personal',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final r in _rolesPersonal)
                        FilterChip(
                          label: Text(etiquetaRolApi(r)),
                          selected: _rolesSel.contains(r),
                          onSelected: (s) => setState(() {
                            if (s) {
                              _rolesSel.add(r);
                            } else {
                              _rolesSel.remove(r);
                            }
                          }),
                        ),
                    ],
                  ),
                  if (widget.usuario!.esMiembro)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Esta persona también es miembro del gimnasio (no se modifica aquí).',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textMuted),
                      ),
                    ),
                ] else ...[
                  DropdownButtonFormField<String>(
                    value: _rol,
                    decoration: const InputDecoration(labelText: 'Rol'),
                    items: _rolesPersonal
                        .map((r) => DropdownMenuItem(
                            value: r, child: Text(etiquetaRolApi(r))))
                        .toList(),
                    onChanged: (v) => setState(() => _rol = v!),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña inicial',
                      helperText:
                          'Se ignora si la persona ya tenía cuenta (conserva la suya)',
                    ),
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
          onPressed: _guardando ? null : () => Navigator.of(context).pop(),
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
