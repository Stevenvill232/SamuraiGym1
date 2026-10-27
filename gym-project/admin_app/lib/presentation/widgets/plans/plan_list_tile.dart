import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_models/shared_models.dart';
import '../../../providers/plans_provider.dart';

final _formatoFecha = DateFormat('d MMM yyyy', 'es');
final _formatoMoneda =
    NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

class PlanListTile extends StatelessWidget {
  final PlanConMiembro item;
  final bool mostrarMiembro;
  final VoidCallback? onUsarTiquetera;

  const PlanListTile({
    super.key,
    required this.item,
    this.mostrarMiembro = true,
    this.onUsarTiquetera,
  });

  @override
  Widget build(BuildContext context) {
    final plan = item.plan;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(width: 4, height: 44, color: _colorEstado(plan.estado)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(plan.tipoPlan.etiqueta,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _colorEstado(plan.estado).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          plan.estado.etiqueta,
                          style: TextStyle(
                              color: _colorEstado(plan.estado),
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (mostrarMiembro)
                    Text('${item.nombreMiembro} · CC ${item.cedulaMiembro}',
                        style: const TextStyle(color: AppColors.textMuted)),
                  Text(
                    plan.diasTotales != null
                        ? 'Vence ${_formatoFecha.format(plan.fechaVencimiento)} · '
                            '${plan.diasRestantes} de ${plan.diasTotales} días disponibles'
                        : 'Vence ${_formatoFecha.format(plan.fechaVencimiento)}',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_formatoMoneda.format(plan.precio),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                if (plan.diasTotales != null && onUsarTiquetera != null)
                  TextButton(
                    onPressed: (plan.estado == EstadoPlan.agotado ||
                            plan.estado == EstadoPlan.vencido)
                        ? null
                        : onUsarTiquetera,
                    child: const Text('Usar día'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _colorEstado(EstadoPlan estado) => switch (estado) {
        EstadoPlan.activo => AppColors.estadoActivo,
        EstadoPlan.porVencer => AppColors.estadoPorVencer,
        EstadoPlan.vencido => AppColors.estadoVencido,
        EstadoPlan.agotado => AppColors.estadoAgotado,
      };
}
