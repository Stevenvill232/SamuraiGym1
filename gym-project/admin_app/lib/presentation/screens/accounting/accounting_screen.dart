import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_models/shared_models.dart';
import '../../../providers/accounting_provider.dart';
import '../../widgets/accounting/gasto_form_dialog.dart';
import '../../widgets/dashboard/kpi_card.dart';

final _formatoMoneda =
    NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
final _formatoFecha = DateFormat('d MMM', 'es');

class AccountingScreen extends ConsumerWidget {
  const AccountingScreen({super.key});

  Future<void> _abrirFormularioGasto(BuildContext context, WidgetRef ref) async {
    final creado = await showDialog<bool>(
      context: context,
      builder: (_) => const GastoFormDialog(),
    );
    if (creado == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gasto registrado correctamente')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountingProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _abrirFormularioGasto(context, ref),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Registrar gasto'),
        ),
        body: RefreshIndicator(
          onRefresh: () => ref.read(accountingProvider.notifier).cargar(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Contabilidad',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Ingresos y gastos del mes en curso',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 20),
                      if (state.error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(state.error!,
                              style:
                                  const TextStyle(color: AppColors.estadoVencido)),
                        ),
                      if (state.resumen != null) _buildResumen(context, state),
                      const SizedBox(height: 24),
                      const TabBar(
                        labelColor: AppColors.ember,
                        unselectedLabelColor: AppColors.textMuted,
                        indicatorColor: AppColors.ember,
                        tabs: [Tab(text: 'Ingresos'), Tab(text: 'Gastos')],
                      ),
                    ],
                  ),
                ),
              ),
              SliverFillRemaining(
                child: state.cargando && state.resumen == null
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        children: [
                          _ListaMovimientos(
                            movimientos: state.ingresos,
                            vacioTexto: 'No hay ingresos este mes',
                          ),
                          _ListaMovimientos(
                            movimientos: state.gastos,
                            vacioTexto: 'No hay gastos este mes',
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResumen(BuildContext context, AccountingState state) {
    final r = state.resumen!;
    return LayoutBuilder(builder: (context, constraints) {
      final columnas = constraints.maxWidth > 700 ? 3 : 1;
      return GridView.count(
        crossAxisCount: columnas,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: columnas == 3 ? 2.2 : 3.2,
        children: [
          KpiCard(
            label: 'Ingresos del mes',
            value: _formatoMoneda.format(r.totalIngresos),
            icon: Icons.arrow_downward_rounded,
            accentColor: AppColors.estadoActivo,
          ),
          KpiCard(
            label: 'Gastos del mes',
            value: _formatoMoneda.format(r.totalGastos),
            icon: Icons.arrow_upward_rounded,
            accentColor: AppColors.estadoVencido,
          ),
          KpiCard(
            label: 'Utilidad del mes',
            value: _formatoMoneda.format(r.utilidad),
            icon: Icons.trending_up_rounded,
          ),
        ],
      );
    });
  }
}

class _ListaMovimientos extends StatelessWidget {
  final List<Movimiento> movimientos;
  final String vacioTexto;
  const _ListaMovimientos({required this.movimientos, required this.vacioTexto});

  @override
  Widget build(BuildContext context) {
    if (movimientos.isEmpty) {
      return Center(
        child: Text(vacioTexto,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textMuted)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 90),
      itemCount: movimientos.length,
      itemBuilder: (context, i) {
        final m = movimientos[i];
        final esIngreso = m.valor >= 0;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(m.concepto),
            subtitle: Text('${m.tipoOCategoria} · ${m.metodoPago} · '
                '${_formatoFecha.format(m.fecha)}'),
            trailing: Text(
              _formatoMoneda.format(m.valor),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: esIngreso ? AppColors.estadoActivo : AppColors.estadoVencido,
              ),
            ),
          ),
        );
      },
    );
  }
}
