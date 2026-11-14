import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import '../../../providers/settings_provider.dart';
import 'settings_common.dart';

/// Información general del gimnasio y preferencias de notificaciones.
class GimnasioTab extends ConsumerStatefulWidget {
  final AppSettings settings;
  const GimnasioTab({super.key, required this.settings});

  @override
  ConsumerState<GimnasioTab> createState() => _GimnasioTabState();
}

class _GimnasioTabState extends ConsumerState<GimnasioTab> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _direccionCtrl;
  late final TextEditingController _horarioCtrl;
  late bool _dosDias;
  late bool _unDia;
  late bool _vencido;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final i = widget.settings.info;
    _nombreCtrl = TextEditingController(text: i.nombre);
    _telefonoCtrl = TextEditingController(text: i.telefono);
    _direccionCtrl = TextEditingController(text: i.direccion);
    _horarioCtrl = TextEditingController(text: i.horarioAtencion);
    final n = widget.settings.notificaciones;
    _dosDias = n.avisarDosDias;
    _unDia = n.avisarUnDia;
    _vencido = n.avisarVencido;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _direccionCtrl.dispose();
    _horarioCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_nombreCtrl.text.trim().isEmpty) {
      setState(() => _error = 'El nombre del gimnasio es obligatorio');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    final error = await ref.read(settingsProvider.notifier).guardarVarias({
      'info_gimnasio': InfoGimnasio(
        nombre: _nombreCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim(),
        direccion: _direccionCtrl.text.trim(),
        horarioAtencion: _horarioCtrl.text.trim(),
      ).toJson(),
      'notificaciones': NotificacionesConfig(
        avisarDosDias: _dosDias,
        avisarUnDia: _unDia,
        avisarVencido: _vencido,
      ).toJson(),
    });
    if (!mounted) return;
    setState(() {
      _guardando = false;
      _error = error;
    });
    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Información guardada')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return TabScroll(
      children: [
        SeccionCard(
          titulo: 'Información del gimnasio',
          descripcion:
              'Los miembros ven el nombre y el teléfono en su app (por ejemplo, para renovar un plan).',
          child: Column(
            children: [
              TextField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _telefonoCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Teléfono'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _direccionCtrl,
                decoration: const InputDecoration(labelText: 'Dirección'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _horarioCtrl,
                decoration: const InputDecoration(
                    labelText: 'Horario de atención',
                    hintText: 'Ej. Lunes a sábado 5:00 a.m. - 9:00 p.m.'),
              ),
            ],
          ),
        ),
        SeccionCard(
          titulo: 'Notificaciones de vencimiento',
          descripcion:
              'Qué avisos recibirá el miembro cuando se active el envío de notificaciones push (próxima fase). Se guardan desde ya.',
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Avisar 2 días antes de vencer'),
                value: _dosDias,
                onChanged: (v) => setState(() => _dosDias = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Avisar 1 día antes de vencer'),
                value: _unDia,
                onChanged: (v) => setState(() => _unDia = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Avisar cuando el plan venza'),
                value: _vencido,
                onChanged: (v) => setState(() => _vencido = v),
              ),
            ],
          ),
        ),
        BotonGuardar(
            guardando: _guardando, error: _error, onPressed: _guardar),
      ],
    );
  }
}
