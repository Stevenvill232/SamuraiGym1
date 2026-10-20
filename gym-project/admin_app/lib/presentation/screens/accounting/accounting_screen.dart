import 'package:flutter/material.dart';
import '../../widgets/module_placeholder.dart';

class AccountingScreen extends StatelessWidget {
  const AccountingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholder(
      title: 'Contabilidad',
      description: 'Ingresos, gastos y estadísticas financieras del gimnasio.',
      icon: Icons.receipt_long_rounded,
      proximamente: [
        'Registro de ingresos (automático desde planes y ventas)',
        'Registro manual de gastos por categoría',
        'Estadísticas: ingresos/gastos por día, semana y mes',
        'Filtros por fecha, tipo de movimiento y método de pago',
        'Gráficos de utilidad, plan más vendido, producto más vendido',
      ],
    );
  }
}
