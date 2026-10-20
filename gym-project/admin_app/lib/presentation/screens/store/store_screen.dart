import 'package:flutter/material.dart';
import '../../widgets/module_placeholder.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholder(
      title: 'Tienda',
      description: 'Inventario de productos y registro de ventas.',
      icon: Icons.storefront_rounded,
      proximamente: [
        'CRUD de productos (precio compra/venta, stock, stock mínimo)',
        'Venta de producto: descuenta stock y genera ingreso automático',
        'Alerta visual cuando el stock llega al mínimo configurado',
        'Bloqueo de venta si la cantidad supera el stock disponible',
      ],
    );
  }
}
