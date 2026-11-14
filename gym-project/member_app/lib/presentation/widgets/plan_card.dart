import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';
import '../../data/member_models.dart';

Color colorEstadoPlan(EstadoPlan e) => switch (e) {
      EstadoPlan.activo => AppColors.estadoActivo,
      EstadoPlan.porVencer => AppColors.estadoPorVencer,
      EstadoPlan.vencido => AppColors.estadoVencido,
      EstadoPlan.agotado => AppColors.estadoAgotado,
    };

/// "Vence en 3 días", "Vence mañana", "Venció hace 2 días"...
String textoVencimiento(PlanDetalle d) {
  final dias = d.diasParaVencer;
  if (d.plan.estado == EstadoPlan.agotado) return 'Tiquetera agotada';
  if (d.plan.estado == EstadoPlan.vencido || dias < 0) {
    final atras = -dias;
    if (atras <= 0) return 'Venció hoy';
    return 'Venció hace $atras ${atras == 1 ? 'día' : 'días'}';
  }
  if (dias == 0) return 'Vence hoy';
  if (dias == 1) return 'Vence mañana';
  return 'Vence en $dias días';
}

/// Mensaje de cómo renovar, con los datos de contacto del gimnasio.
String? textoContacto(AppSettings? s) {
  if (s == null) return null;
  final i = s.info;
  return i.telefono.isEmpty
      ? 'Para renovar, comunícate con ${i.nombre}.'
      : 'Para renovar, comunícate con ${i.nombre}: ${i.telefono}.';
}

class EstadoChip extends StatelessWidget {
  final EstadoPlan estado;
  const EstadoChip({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    final color = colorEstadoPlan(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado.etiqueta,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Tarjeta de un plan. Con [detallado] muestra además las observaciones y,
/// en tiqueteras, el historial de días utilizados.
class PlanCard extends StatelessWidget {
  final PlanDetalle detalle;
  final bool detallado;
  final String? contacto;

  const PlanCard({
    super.key,
    required this.detalle,
    this.detallado = false,
    this.contacto,
  });

  IconData _icono(TipoPlan t) {
    if (t.esTiquetera) return Icons.confirmation_number_rounded;
    if (t == TipoPlan.boxeo || t == TipoPlan.karate || t == TipoPlan.mma) {
      return Icons.sports_mma_rounded;
    }
    return Icons.fitness_center_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final plan = detalle.plan;
    final color = colorEstadoPlan(plan.estado);
    final text = Theme.of(context).textTheme;
    final muted = text.bodySmall?.copyWith(color: AppColors.textMuted);
    final requiereRenovar = plan.estado != EstadoPlan.activo;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_icono(plan.tipoPlan), color: AppColors.ember, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(plan.tipoPlan.etiqueta,
                      style: text.titleMedium),
                ),
                EstadoChip(estado: plan.estado),
              ],
            ),
            const SizedBox(height: 12),
            if (plan.tipoPlan.esTiquetera)
              ..._bloqueTiquetera(context, plan, color, muted)
            else
              ..._bloqueVigencia(context, plan, color, muted),
            if (detalle.horario != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    const Icon(Icons.schedule_rounded,
                        size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Text(detalle.horario!.etiqueta),
                  ],
                ),
              ),
            if (requiereRenovar && contacto != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(contacto!, style: text.bodySmall),
              ),
            if (detallado &&
                plan.observaciones != null &&
                plan.observaciones!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text('Nota: ${plan.observaciones}', style: muted),
              ),
            if (detallado && plan.tipoPlan.esTiquetera)
              ..._historialUsos(context, muted),
          ],
        ),
      ),
    );
  }

  List<Widget> _bloqueVigencia(
      BuildContext context, Plan plan, Color color, TextStyle? muted) {
    return [
      Text(
        '${FormatoFecha.conAnio(plan.fechaInicio)}  →  ${FormatoFecha.conAnio(plan.fechaVencimiento)}',
        style: muted,
      ),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: detalle.progresoTiempo,
          minHeight: 8,
          color: color,
          backgroundColor: AppColors.borderSubtle,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        textoVencimiento(detalle),
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    ];
  }

  List<Widget> _bloqueTiquetera(
      BuildContext context, Plan plan, Color color, TextStyle? muted) {
    final total = plan.diasTotales ?? 0;
    final usados = plan.diasUtilizados;
    return [
      Row(
        children: [
          Text('$usados de $total días usados',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('Quedan ${plan.diasRestantes ?? 0}',
              style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: total == 0 ? 0 : (usados / total).clamp(0.0, 1.0),
          minHeight: 8,
          color: color,
          backgroundColor: AppColors.borderSubtle,
        ),
      ),
      const SizedBox(height: 8),
      Text('Vigencia hasta ${FormatoFecha.conAnio(plan.fechaVencimiento)}',
          style: muted),
      Text(
        textoVencimiento(detalle),
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    ];
  }

  List<Widget> _historialUsos(BuildContext context, TextStyle? muted) {
    return [
      const Divider(height: 28),
      Text('Días utilizados',
          style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      if (detalle.usos.isEmpty)
        Text('Aún no has usado ningún día', style: muted)
      else
        for (var i = 0; i < detalle.usos.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 16, color: AppColors.estadoActivo),
                const SizedBox(width: 8),
                Text(
                    'Día ${i + 1} · ${FormatoFecha.diaMesLargo(detalle.usos[i])}'),
              ],
            ),
          ),
    ];
  }
}
