import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import '../../../providers/members_provider.dart';

/// Se usa tanto para crear (miembro == null) como para editar. La cédula y
/// la contraseña solo se piden al crear: la cédula es inmutable (regla de
/// negocio) y la contraseña tiene su propio flujo de cambio más adelante.
class MemberFormDialog extends ConsumerStatefulWidget {
  final Usuario? miembro;
  const MemberFormDialog({super.key, this.miembro});

  @override
  ConsumerState<MemberFormDialog> createState() => _MemberFormDialogState();
}

class _MemberFormDialogState extends ConsumerState<MemberFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _cedulaCtrl;
  late final TextEditingController _nombresCtrl;
  late final TextEditingController _apellidosCtrl;
  late final TextEditingController _celularCtrl;
  late final TextEditingController _correoCtrl;
  late final TextEditingController _direccionCtrl;
  final _passwordCtrl = TextEditingController();
  DateTime? _fechaNacimiento;
  String? _sexo;
  bool _guardando = false;
  String? _error;

  bool get _esEdicion => widget.miembro != null;

  @override
  void initState() {
    super.initState();
    final m = widget.miembro;
    _cedulaCtrl = TextEditingController(text: m?.cedula ?? '');
    _nombresCtrl = TextEditingController(text: m?.nombres ?? '');
    _apellidosCtrl = TextEditingController(text: m?.apellidos ?? '');
    _celularCtrl = TextEditingController(text: m?.celular ?? '');
    _correoCtrl = TextEditingController(text: m?.correo ?? '');
    _direccionCtrl = TextEditingController(text: m?.direccion ?? '');
    _fechaNacimiento = m?.fechaNacimiento;
    _sexo = m?.sexo;
  }

  @override
  void dispose() {
    _cedulaCtrl.dispose();
    _nombresCtrl.dispose();
    _apellidosCtrl.dispose();
    _celularCtrl.dispose();
    _correoCtrl.dispose();
    _direccionCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
    );
    if (fecha != null) setState(() => _fechaNacimiento = fecha);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });

    final notifier = ref.read(membersProvider.notifier);
    final error = _esEdicion
        ? await notifier.actualizar(
            widget.miembro!.id,
            nombres: _nombresCtrl.text.trim(),
            apellidos: _apellidosCtrl.text.trim(),
            fechaNacimiento: _fechaNacimiento,
            celular: _celularCtrl.text.trim(),
            correo: _correoCtrl.text.trim(),
            direccion: _direccionCtrl.text.trim(),
            sexo: _sexo,
          )
        : await notifier.crear(
            cedula: _cedulaCtrl.text.trim(),
            nombres: _nombresCtrl.text.trim(),
            apellidos: _apellidosCtrl.text.trim(),
            password: _passwordCtrl.text,
            fechaNacimiento: _fechaNacimiento,
            celular: _celularCtrl.text.trim(),
            correo: _correoCtrl.text.trim(),
            direccion: _direccionCtrl.text.trim(),
            sexo: _sexo,
          );

    if (!mounted) return;
    if (error != null) {
      setState(() {
        _guardando = false;
        _error = error;
      });
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _esEdicion ? 'Editar miembro' : 'Nuevo miembro',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _cedulaCtrl,
                          enabled: !_esEdicion,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Cédula',
                            helperText: 'No se puede editar luego de creado',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Requerido'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _nombresCtrl,
                                decoration:
                                    const InputDecoration(labelText: 'Nombres'),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Requerido'
                                        : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _apellidosCtrl,
                                decoration: const InputDecoration(
                                    labelText: 'Apellidos'),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Requerido'
                                        : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (!_esEdicion) ...[
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: true,
                            decoration: const InputDecoration(
                                labelText: 'Contraseña inicial'),
                            validator: (v) => (v == null || v.length < 6)
                                ? 'Mínimo 6 caracteres'
                                : null,
                          ),
                          const SizedBox(height: 14),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _seleccionarFecha,
                                icon: const Icon(Icons.cake_outlined, size: 18),
                                label: Text(
                                  _fechaNacimiento == null
                                      ? 'Fecha de nacimiento'
                                      : '${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _sexo,
                                decoration:
                                    const InputDecoration(labelText: 'Sexo'),
                                items: const [
                                  DropdownMenuItem(value: 'M', child: Text('M')),
                                  DropdownMenuItem(value: 'F', child: Text('F')),
                                ],
                                onChanged: (v) => setState(() => _sexo = v),
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
                        TextFormField(
                          controller: _correoCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Correo'),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _direccionCtrl,
                          decoration: const InputDecoration(labelText: 'Dirección'),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Text(_error!,
                              style:
                                  const TextStyle(color: AppColors.estadoVencido)),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _guardando
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _guardando ? null : _guardar,
                      child: _guardando
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(_esEdicion ? 'Guardar cambios' : 'Crear miembro'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
