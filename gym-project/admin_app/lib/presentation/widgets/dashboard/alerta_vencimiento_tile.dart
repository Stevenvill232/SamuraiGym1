import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_models/shared_models.dart';

/// Refleja EXACTAMENTE la regla de negocio del proyecto:
///   - naranja: faltan exactamente 2 días
///   - rojo: falta exactamente 1 día
///   - gris: venció hoy o hace máximo 1 día
///   - más de 1 día vencido -> no se muestra en el Dashboard
enum SeveridadAlerta { dosDias, unDia, vencidaReciente }

class AlertaVencimiento {
  final String nombreMiembro;
  final String? foto;
  final String tipoPlan;
  final DateTime fechaVencimiento;
  final SeveridadAlerta severidad;

  const AlertaVencimiento({
    required this.nombreMiembro,
    required this.tipoPlan,
    required this.fechaVencimiento,
    required this.severidad,
    this.foto,
  });

  Color get color => switch (severidad) {
        SeveridadAlerta.dosDias => AppColors.alertaDosDias,
        SeveridadAlerta.unDia => AppColors.alertaUnDia,
        SeveridadAlerta.vencidaReciente => AppColors.alertaVencidaReciente,
      };

  String get etiquetaEstado => switch (severidad) {
        SeveridadAlerta.dosDias => 'Vence en 2 días',
        SeveridadAlerta.unDia => 'Vence mañana',
        SeveridadAlerta.vencidaReciente => 'Vencido',
      };
}

class AlertaVencimientoTile extends StatelessWidget {
  final AlertaVencimiento alerta;
  const AlertaVencimientoTile({super.key, required this.alerta});

  @override
  Widget build(BuildContext context) {
    final fecha = DateFormat('d MMM', 'es').format(alerta.fechaVencimiento);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(width: 4, height: 40, color: alerta.color),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.background,
            backgroundImage:
                alerta.foto != null ? NetworkImage(alerta.foto!) : null,
            child: alerta.foto == null
                ? const Icon(Icons.person_rounded, color: AppColors.textMuted)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alerta.nombreMiembro,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text('${alerta.tipoPlan} · vence $fecha',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: alerta.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              alerta.etiquetaEstado,
              style: TextStyle(
                  color: alerta.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
