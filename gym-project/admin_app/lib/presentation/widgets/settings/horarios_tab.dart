import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import '../../../providers/auth_provider.dart';
import 'settings_common.dart';

final horariosAdminProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final data = await ref.watch(apiClientProvider).getList('/schedules');
  return data.cast<Map<String, dynamic>>();
});

const _deportes = ['BOXEO', 'KARATE', 'MMA'];
const _dias = [
  'LUNES',
  'MARTES',
  'MIERCOLES',
  'JUEVES',
  'VIERNES',
  'SABADO',
  'DOMINGO',
];

String _etiquetaDia(String d) => switch (d) {
      'LUNES' => 'Lunes',
      'MARTES' => 'Martes',
      'MIERCOLES' => 'Miércoles',
      'JUEVES' => 'Jueves',
      'VIERNES' => 'Viernes',
      'SABADO' => 'Sábado',
      'DOMINGO' => 'Domingo',
      _ => d,
    };

String _etiquetaDeporte(String d) => switch (d) {
      'BOXEO' => 'Boxeo',
      'KARATE' => 'Karate',
      _ => 'MMA',
    };

/// Horarios de Boxeo, Karate y MMA. Los puede gestionar el administrador
/// y el entrenador (sección 25 del proyecto).
class HorariosTab extends ConsumerWidget {
  const HorariosTab({super.key});

  Future<void> _abrir(BuildContext context, WidgetRef ref,
      {Map<String, dynamic>? horario}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => horario == null
          ? const HorariosBulkDialog()
          : HorarioDialog(horario: horario),
    );
    if (ok == true) ref.invalidate(horariosAdminProvider);
  }

  Future<void> _eliminar(
      BuildContext context, WidgetRef ref, Map<String, dynamic> h) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desactivar horario'),
        content: const Text(
            'Los miembros que ya tienen este horario en su plan lo conservan; '
            'solo dejará de ofrecerse para planes nuevos.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.estadoVencido),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await ref.read(apiClientProvider).delete('/schedules/${h['id']}');
      ref.invalidate(horariosAdminProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(horariosAdminProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          e is ApiException ? e.message : 'No se pudieron cargar los horarios',
          style: const TextStyle(color: AppColors.estadoVencido),
        ),
      ),
      data: (horarios) => TabScroll(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Estos horarios se ofrecen al registrar un plan de Boxeo, Karate o MMA.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textMuted),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _abrir(context, ref),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Nuevo horario'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final deporte in _deportes)
            SeccionCard(
              titulo: _etiquetaDeporte(deporte),
              child: Builder(builder: (context) {
                final lista =
                    horarios.where((h) => h['deporte'] == deporte).toList();
                if (lista.isEmpty) {
                  return const Text('Sin horarios configurados',
                      style: TextStyle(color: AppColors.textMuted));
                }
                return Column(
                  children: [
                    for (final h in lista)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.schedule_rounded,
                            color: AppColors.textMuted),
                        title: Text(
                            '${_etiquetaDia(h['dia'] as String)} · ${h['horaInicio']} - ${h['horaFin']}'),
                        subtitle: h['cupo'] != null
                            ? Text('Cupo: ${h['cupo']}')
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Editar',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _abrir(context, ref, horario: h),
                            ),
                            IconButton(
                              tooltip: 'Desactivar',
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: AppColors.estadoVencido),
                              onPressed: () => _eliminar(context, ref, h),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              }),
            ),
        ],
      ),
    );
  }
}

class HorarioDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? horario;
  const HorarioDialog({super.key, this.horario});

  @override
  ConsumerState<HorarioDialog> createState() => _HorarioDialogState();
}

class _HorarioDialogState extends ConsumerState<HorarioDialog> {
  late String _deporte;
  late String _dia;
  TimeOfDay? _inicio;
  TimeOfDay? _fin;
  final _cupoCtrl = TextEditingController();
  bool _guardando = false;
  String? _error;

  bool get _esEdicion => widget.horario != null;

  static TimeOfDay _parse(String s) {
    final p = s.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  static String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    final h = widget.horario;
    _deporte = (h?['deporte'] as String?) ?? 'BOXEO';
    _dia = (h?['dia'] as String?) ?? 'LUNES';
    if (h != null) {
      _inicio = _parse(h['horaInicio'] as String);
      _fin = _parse(h['horaFin'] as String);
      _cupoCtrl.text = h['cupo']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _cupoCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirHora(bool esInicio) async {
    final t = await showTimePicker(
      context: context,
      initialTime: (esInicio ? _inicio : _fin) ??
          const TimeOfDay(hour: 18, minute: 0),
    );
    if (t != null) setState(() => esInicio ? _inicio = t : _fin = t);
  }

  Future<void> _guardar() async {
    if (_inicio == null || _fin == null) {
      setState(() => _error = 'Selecciona la hora de inicio y la de fin');
      return;
    }
    final minIni = _inicio!.hour * 60 + _inicio!.minute;
    final minFin = _fin!.hour * 60 + _fin!.minute;
    if (minFin <= minIni) {
      setState(() => _error = 'La hora de fin debe ser posterior a la de inicio');
      return;
    }
    final cupoTxt = _cupoCtrl.text.trim();
    final cupo = cupoTxt.isEmpty ? null : int.tryParse(cupoTxt);
    if (cupoTxt.isNotEmpty && (cupo == null || cupo < 1)) {
      setState(() => _error = 'El cupo debe ser un número mayor a 0');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });
    final body = {
      'deporte': _deporte,
      'dia': _dia,
      'horaInicio': _fmt(_inicio!),
      'horaFin': _fmt(_fin!),
      'cupo': cupo,
    };
    try {
      final api = ref.read(apiClientProvider);
      if (_esEdicion) {
        await api.patch('/schedules/${widget.horario!['id']}', body: body);
      } else {
        await api.post('/schedules', body: body);
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
      title: Text(_esEdicion ? 'Editar horario' : 'Nuevo horario'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _deporte,
                    decoration: const InputDecoration(labelText: 'Deporte'),
                    items: _deportes
                        .map((d) => DropdownMenuItem(
                            value: d, child: Text(_etiquetaDeporte(d))))
                        .toList(),
                    onChanged: (v) => setState(() => _deporte = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _dia,
                    decoration: const InputDecoration(labelText: 'Día'),
                    items: _dias
                        .map((d) => DropdownMenuItem(
                            value: d, child: Text(_etiquetaDia(d))))
                        .toList(),
                    onChanged: (v) => setState(() => _dia = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _elegirHora(true),
                    icon: const Icon(Icons.schedule_rounded, size: 18),
                    label: Text(
                        _inicio == null ? 'Hora de inicio' : _fmt(_inicio!)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _elegirHora(false),
                    icon: const Icon(Icons.schedule_rounded, size: 18),
                    label: Text(_fin == null ? 'Hora de fin' : _fmt(_fin!)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _cupoCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Cupo (opcional)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: const TextStyle(color: AppColors.estadoVencido)),
            ],
          ],
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

class _FranjaEdit {
  String dia;
  TimeOfDay? inicio;
  TimeOfDay? fin;
  _FranjaEdit(this.dia, [this.inicio, this.fin]);
}

/// Crea de una vez los horarios de un deporte, cada uno con su día y su hora
/// (ej. Lunes 17:00-18:00, Miércoles 17:00-18:00, Viernes 18:00-19:00).
class HorariosBulkDialog extends ConsumerStatefulWidget {
  const HorariosBulkDialog({super.key});

  @override
  ConsumerState<HorariosBulkDialog> createState() =>
      _HorariosBulkDialogState();
}

class _HorariosBulkDialogState extends ConsumerState<HorariosBulkDialog> {
  String _deporte = 'BOXEO';
  final List<_FranjaEdit> _franjas = [
    _FranjaEdit('LUNES', const TimeOfDay(hour: 18, minute: 0),
        const TimeOfDay(hour: 19, minute: 0)),
  ];
  final _cupoCtrl = TextEditingController();
  bool _guardando = false;
  String? _error;

  static String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _cupoCtrl.dispose();
    super.dispose();
  }

  void _agregarFranja() {
    // Propone el siguiente día libre y copia la hora de la franja anterior.
    final usados = _franjas.map((f) => f.dia).toSet();
    final siguiente =
        _dias.firstWhere((d) => !usados.contains(d), orElse: () => _dias.first);
    final ultima = _franjas.isNotEmpty ? _franjas.last : null;
    setState(
        () => _franjas.add(_FranjaEdit(siguiente, ultima?.inicio, ultima?.fin)));
  }

  Future<void> _elegirHora(_FranjaEdit f, bool esInicio) async {
    final t = await showTimePicker(
      context: context,
      initialTime:
          (esInicio ? f.inicio : f.fin) ?? const TimeOfDay(hour: 18, minute: 0),
    );
    if (t != null) setState(() => esInicio ? f.inicio = t : f.fin = t);
  }

  Future<void> _guardar() async {
    final vistos = <String>{};
    for (final f in _franjas) {
      if (f.inicio == null || f.fin == null) {
        setState(() => _error = 'Completa la hora de inicio y fin de cada día');
        return;
      }
      if (f.fin!.hour * 60 + f.fin!.minute <=
          f.inicio!.hour * 60 + f.inicio!.minute) {
        setState(() => _error =
            'En ${_etiquetaDia(f.dia)} la hora de fin debe ser posterior a la de inicio');
        return;
      }
      if (!vistos.add('${f.dia}|${_fmt(f.inicio!)}|${_fmt(f.fin!)}')) {
        setState(() => _error =
            '${_etiquetaDia(f.dia)} ${_fmt(f.inicio!)}-${_fmt(f.fin!)} está repetido');
        return;
      }
    }
    final cupoTxt = _cupoCtrl.text.trim();
    final cupo = cupoTxt.isEmpty ? null : int.tryParse(cupoTxt);
    if (cupoTxt.isNotEmpty && (cupo == null || cupo < 1)) {
      setState(() => _error = 'El cupo debe ser un número mayor a 0');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await ref.read(apiClientProvider).post('/schedules/bulk', body: {
        'deporte': _deporte,
        'franjas': [
          for (final f in _franjas)
            {
              'dia': f.dia,
              'horaInicio': _fmt(f.inicio!),
              'horaFin': _fmt(f.fin!),
            },
        ],
        if (cupo != null) 'cupo': cupo,
      });
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _guardando = false;
          _error = e.message;
        });
      }
    } catch (_) {
      // Cualquier otro fallo inesperado: nunca dejar el diálogo cargando.
      if (mounted) {
        setState(() {
          _guardando = false;
          _error = 'No se pudo guardar. Intenta de nuevo.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo horario'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _deporte,
                decoration: const InputDecoration(labelText: 'Deporte'),
                items: _deportes
                    .map((d) => DropdownMenuItem(
                        value: d, child: Text(_etiquetaDeporte(d))))
                    .toList(),
                onChanged: (v) => setState(() => _deporte = v!),
              ),
              const SizedBox(height: 16),
              Text('Días y horas en que se entrena',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              const Text(
                'Cada día puede tener su propia hora. Un miembro podrá elegir uno o varios de estos horarios.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < _franjas.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          value: _franjas[i].dia,
                          isDense: true,
                          decoration: const InputDecoration(labelText: 'Día'),
                          items: _dias
                              .map((d) => DropdownMenuItem(
                                  value: d, child: Text(_etiquetaDia(d))))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _franjas[i].dia = v!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: OutlinedButton(
                          onPressed: () => _elegirHora(_franjas[i], true),
                          child: Text(_franjas[i].inicio == null
                              ? 'Inicio'
                              : _fmt(_franjas[i].inicio!)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: OutlinedButton(
                          onPressed: () => _elegirHora(_franjas[i], false),
                          child: Text(_franjas[i].fin == null
                              ? 'Fin'
                              : _fmt(_franjas[i].fin!)),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Quitar este día',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: _franjas.length == 1
                            ? null
                            : () => setState(() => _franjas.removeAt(i)),
                      ),
                    ],
                  ),
                ),
              TextButton.icon(
                onPressed: _franjas.length >= 14 ? null : _agregarFranja,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Agregar otro día'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _cupoCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Cupo por clase (opcional)'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(color: AppColors.estadoVencido)),
              ],
            ],
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
          child: Text(_franjas.length == 1
              ? 'Crear horario'
              : 'Crear ${_franjas.length} horarios'),
        ),
      ],
    );
  }
}
