import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';
import '../../../data/member_models.dart';
import '../../../providers/member_providers.dart';

class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(profileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Datos personales')),
      body: perfil.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            e is ApiException ? e.message : 'No se pudo cargar tu perfil',
            style: const TextStyle(color: AppColors.estadoVencido),
          ),
        ),
        data: (p) => _EditForm(perfil: p),
      ),
    );
  }
}

class _EditForm extends ConsumerStatefulWidget {
  final MemberProfile perfil;
  const _EditForm({required this.perfil});

  @override
  ConsumerState<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends ConsumerState<_EditForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombres;
  late final TextEditingController _apellidos;
  late final TextEditingController _celular;
  late final TextEditingController _correo;
  late final TextEditingController _direccion;
  String? _sexo;
  DateTime? _fecha;
  bool _guardando = false;
  String? _error;

  bool get _fechaBloqueada => widget.perfil.fechaNacimiento != null;

  @override
  void initState() {
    super.initState();
    final p = widget.perfil;
    _nombres = TextEditingController(text: p.nombres);
    _apellidos = TextEditingController(text: p.apellidos);
    _celular = TextEditingController(text: p.celular ?? '');
    _correo = TextEditingController(text: p.correo ?? '');
    _direccion = TextEditingController(text: p.direccion ?? '');
    _sexo = (p.sexo == 'M' || p.sexo == 'F') ? p.sexo : null;
  }

  @override
  void dispose() {
    _nombres.dispose();
    _apellidos.dispose();
    _celular.dispose();
    _correo.dispose();
    _direccion.dispose();
    super.dispose();
  }

  String? _vacioANull(String s) => s.trim().isEmpty ? null : s.trim();

  Future<void> _elegirFecha() async {
    final f = await showDatePicker(
      context: context,
      initialDate: _fecha ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
    );
    if (f != null) setState(() => _fecha = f);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });

    final cambios = <String, dynamic>{
      'nombres': _nombres.text.trim(),
      'apellidos': _apellidos.text.trim(),
      'celular': _vacioANull(_celular.text),
      'correo': _vacioANull(_correo.text),
      'direccion': _vacioANull(_direccion.text),
      'sexo': _sexo,
      if (_fecha != null && !_fechaBloqueada)
        'fechaNacimiento': _fecha!.toIso8601String(),
    };

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(memberRepositoryProvider).actualizarPerfil(cambios);
      ref.invalidate(profileProvider);
      ref.invalidate(memberDashboardProvider);
      if (!mounted) return;
      messenger.showSnackBar(
          const SnackBar(content: Text('Datos actualizados correctamente')));
      context.pop();
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
    final p = widget.perfil;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextFormField(
            initialValue: p.cedula,
            enabled: false,
            decoration: const InputDecoration(
              labelText: 'Cédula',
              helperText: 'Tu cédula no se puede modificar',
              suffixIcon: Icon(Icons.lock_outline_rounded),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nombres,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nombres'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Requerido' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _apellidos,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Apellidos'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Requerido' : null,
          ),
          const SizedBox(height: 16),
          if (_fechaBloqueada)
            TextFormField(
              initialValue: FormatoFecha.sinZona(p.fechaNacimiento!),
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Fecha de nacimiento',
                helperText:
                    'Para cambiarla comunícate con el gimnasio',
                suffixIcon: Icon(Icons.lock_outline_rounded),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutlinedButton.icon(
                  onPressed: _elegirFecha,
                  icon: const Icon(Icons.cake_outlined, size: 18),
                  label: Text(_fecha == null
                      ? 'Fecha de nacimiento'
                      : FormatoFecha.sinZona(_fecha!)),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    'Solo puedes registrarla una vez.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String?>(
            value: _sexo,
            decoration: const InputDecoration(labelText: 'Sexo'),
            items: const [
              DropdownMenuItem<String?>(
                  value: null, child: Text('Sin especificar')),
              DropdownMenuItem<String?>(value: 'M', child: Text('Masculino')),
              DropdownMenuItem<String?>(value: 'F', child: Text('Femenino')),
            ],
            onChanged: (v) => setState(() => _sexo = v),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _celular,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Celular'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _correo,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Correo electrónico'),
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.isEmpty) return null;
              return (t.contains('@') && t.contains('.'))
                  ? null
                  : 'Correo inválido';
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _direccion,
            decoration: const InputDecoration(labelText: 'Dirección'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppColors.estadoVencido)),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _guardando ? null : _guardar,
            child: _guardando
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Guardar cambios'),
          ),
        ],
      ),
    );
  }
}
