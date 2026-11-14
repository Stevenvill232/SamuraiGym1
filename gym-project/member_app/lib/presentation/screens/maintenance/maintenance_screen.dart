import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import '../../../data/member_models.dart';
import '../../../providers/member_providers.dart';

/// "Mantenimiento" / Progreso: registro periódico de peso y estatura, con
/// gráfico de evolución e historial. Estos datos alimentarán la IA (Fase 7).
class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});

  Future<void> _registrar(BuildContext context, WidgetRef ref,
      List<RegistroFisico> registros) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) =>
          _MedidasDialog(ultimo: registros.isEmpty ? null : registros.first),
    );
    if (ok == true) _refrescar(ref);
  }

  void _refrescar(WidgetRef ref) {
    ref.invalidate(progressProvider);
    ref.invalidate(memberDashboardProvider);
    ref.invalidate(profileProvider);
  }

  Future<void> _eliminar(
      BuildContext context, WidgetRef ref, RegistroFisico r) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: Text(
            '¿Eliminar el registro del ${FormatoFecha.conAnio(r.fecha)} (${r.peso.toStringAsFixed(1)} kg)?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.estadoVencido),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await ref.read(memberRepositoryProvider).eliminarRegistro(r.id);
      _refrescar(ref);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(progressProvider);
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: AppColors.textMuted);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(progressProvider.future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text('Progreso', style: text.headlineSmall),
          const SizedBox(height: 4),
          Text('La evolución de tu peso y estatura', style: muted),
          const SizedBox(height: 20),
          ...async.when<List<Widget>>(
            loading: () => const [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (e, _) => [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e is ApiException
                            ? e.message
                            : 'No se pudo cargar tu progreso',
                        style:
                            const TextStyle(color: AppColors.estadoVencido),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => ref.invalidate(progressProvider),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            data: (registros) => _contenido(context, ref, registros),
          ),
        ],
      ),
    );
  }

  List<Widget> _contenido(
      BuildContext context, WidgetRef ref, List<RegistroFisico> registros) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: AppColors.textMuted);
    // El backend entrega del más reciente al más antiguo.
    final actual = registros.isEmpty ? null : registros.first;
    final anterior = registros.length >= 2 ? registros[1] : null;
    final diferencia =
        (actual != null && anterior != null) ? actual.peso - anterior.peso : null;
    final ascendente = registros.reversed.toList();

    return [
      Row(
        children: [
          Expanded(
            child: _Stat(
              icono: Icons.monitor_weight_rounded,
              etiqueta: 'Peso actual',
              valor: actual != null
                  ? '${actual.peso.toStringAsFixed(1)} kg'
                  : '—',
              nota: diferencia == null
                  ? null
                  : '${diferencia >= 0 ? '+' : '−'}${diferencia.abs().toStringAsFixed(1)} kg vs. anterior',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _Stat(
              icono: Icons.height_rounded,
              etiqueta: 'Estatura',
              valor: actual != null
                  ? '${actual.estatura.toStringAsFixed(2)} m'
                  : '—',
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      ElevatedButton.icon(
        onPressed: () => _registrar(context, ref, registros),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Registrar medidas'),
      ),
      const SizedBox(height: 20),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Evolución del peso', style: text.titleMedium),
              const SizedBox(height: 12),
              if (ascendente.length >= 2)
                _PesoChart(registros: ascendente)
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    ascendente.isEmpty
                        ? 'Registra tu primer peso para empezar tu seguimiento.'
                        : 'Registra al menos una medida más para ver tu gráfico.',
                    style: muted,
                  ),
                ),
            ],
          ),
        ),
      ),
      if (registros.isNotEmpty) ...[
        const SizedBox(height: 20),
        Text('Historial', style: text.titleMedium),
        const SizedBox(height: 10),
        for (final r in registros)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(
                  '${r.peso.toStringAsFixed(1)} kg · ${r.estatura.toStringAsFixed(2)} m'),
              subtitle: Text(FormatoFecha.conAnio(r.fecha)),
              trailing: IconButton(
                tooltip: 'Eliminar',
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.estadoVencido),
                onPressed: () => _eliminar(context, ref, r),
              ),
            ),
          ),
      ],
    ];
  }
}

class _Stat extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;
  final String? nota;
  const _Stat({
    required this.icono,
    required this.etiqueta,
    required this.valor,
    this.nota,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: AppColors.textMuted);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: AppColors.ember, size: 20),
            const SizedBox(height: 10),
            Text(valor, style: Theme.of(context).textTheme.titleLarge),
            Text(etiqueta, style: muted),
            if (nota != null) Text(nota!, style: muted),
          ],
        ),
      ),
    );
  }
}

class _PesoChart extends StatelessWidget {
  /// Ordenados del más antiguo al más reciente.
  final List<RegistroFisico> registros;
  const _PesoChart({required this.registros});

  @override
  Widget build(BuildContext context) {
    const small = TextStyle(fontSize: 11, color: AppColors.textMuted);
    final n = registros.length;
    final pesos = registros.map((r) => r.peso).toList();
    final minY = pesos.reduce(math.min) - 2;
    final maxY = pesos.reduce(math.max) + 2;
    final intervalo = math.max(1, (n / 4).ceil()).toDouble();

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (n - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (v, meta) => Text(
                  v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1),
                  style: small,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: intervalo,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i >= n) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(FormatoFecha.diaMes(registros[i].fecha),
                        style: small),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < n; i++) FlSpot(i.toDouble(), pesos[i]),
              ],
              isCurved: true,
              color: AppColors.ember,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.ember.withValues(alpha: 0.10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedidasDialog extends ConsumerStatefulWidget {
  final RegistroFisico? ultimo;
  const _MedidasDialog({this.ultimo});

  @override
  ConsumerState<_MedidasDialog> createState() => _MedidasDialogState();
}

class _MedidasDialogState extends ConsumerState<_MedidasDialog> {
  final _pesoCtrl = TextEditingController();
  late final TextEditingController _estaturaCtrl;
  DateTime _fecha = DateTime.now();
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _estaturaCtrl = TextEditingController(
        text: widget.ultimo?.estatura.toStringAsFixed(2) ?? '');
  }

  @override
  void dispose() {
    _pesoCtrl.dispose();
    _estaturaCtrl.dispose();
    super.dispose();
  }

  double? _num(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

  bool get _esHoy {
    final h = DateTime.now();
    return _fecha.year == h.year && _fecha.month == h.month && _fecha.day == h.day;
  }

  Future<void> _elegirFecha() async {
    final f = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (f != null) setState(() => _fecha = f);
  }

  Future<void> _guardar() async {
    final peso = _num(_pesoCtrl.text);
    var estatura = _num(_estaturaCtrl.text);
    if (peso == null || peso < 20 || peso > 400) {
      setState(() => _error = 'Ingresa un peso válido en kg (entre 20 y 400)');
      return;
    }
    if (estatura == null) {
      setState(() => _error = 'Ingresa tu estatura (ej. 1.70)');
      return;
    }
    // Si la escriben en centímetros (170) se convierte a metros (1.70).
    if (estatura > 3) estatura = estatura / 100;
    if (estatura < 0.5 || estatura > 2.5) {
      setState(() => _error = 'La estatura debe estar entre 0.5 y 2.5 m');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });
    // Hoy -> momento exacto (para ordenar bien varios registros del día);
    // otra fecha -> mediodía local, para que no cambie de día por zona horaria.
    final fecha = _esHoy
        ? DateTime.now()
        : DateTime(_fecha.year, _fecha.month, _fecha.day, 12);
    try {
      await ref
          .read(memberRepositoryProvider)
          .registrarMedidas(peso: peso, estatura: estatura, fecha: fecha);
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
      title: const Text('Registrar medidas'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _pesoCtrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Peso', suffixText: 'kg'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _estaturaCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Estatura', suffixText: 'm'),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _elegirFecha,
              icon: const Icon(Icons.event_rounded, size: 18),
              label: Text(_esHoy ? 'Hoy' : FormatoFecha.conAnio(_fecha)),
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
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
