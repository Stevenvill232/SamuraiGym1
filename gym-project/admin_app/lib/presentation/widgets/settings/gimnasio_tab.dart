import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import '../../../providers/auth_provider.dart';
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
  bool _generando = false;
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

  /// Los avisos se generan solos (al iniciar el servidor y cada hora); este
  /// botón los fuerza ahora mismo, útil para probar.
  Future<void> _generarAvisos() async {
    setState(() => _generando = true);
    String texto;
    try {
      final r = await ref.read(apiClientProvider).post('/notifications/run-job');
      texto = 'Listo: ${r['nuevas']} aviso(s) nuevo(s) generado(s).';
    } on ApiException catch (e) {
      texto = e.message;
    }
    if (!mounted) return;
    setState(() => _generando = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
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
              'Qué avisos de vencimiento recibe el miembro en su app. Se generan solos al iniciar el servidor y cada hora.',
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
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _generando ? null : _generarAvisos,
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: Text(_generando
                      ? 'Generando...'
                      : 'Generar avisos ahora'),
                ),
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
