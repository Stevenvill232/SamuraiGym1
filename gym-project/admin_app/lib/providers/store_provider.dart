import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'auth_provider.dart';

class Producto {
  final String id;
  final String nombre;
  final String? descripcion;
  final String? categoria;
  final double precioCompra;
  final double precioVenta;
  final int stock;
  final int stockMinimo;

  const Producto({
    required this.id,
    required this.nombre,
    required this.precioCompra,
    required this.precioVenta,
    required this.stock,
    required this.stockMinimo,
    this.descripcion,
    this.categoria,
  });

  bool get stockBajo => stock <= stockMinimo;

  factory Producto.fromJson(Map<String, dynamic> j) => Producto(
        id: j['id'] as String,
        nombre: j['nombre'] as String,
        descripcion: j['descripcion'] as String?,
        categoria: j['categoria'] as String?,
        precioCompra: double.parse(j['precioCompra'].toString()),
        precioVenta: double.parse(j['precioVenta'].toString()),
        stock: j['stock'] as int,
        stockMinimo: j['stockMinimo'] as int,
      );
}

class StoreState {
  final List<Producto> productos;
  final bool cargando;
  final String? error;

  const StoreState({
    this.productos = const [],
    this.cargando = false,
    this.error,
  });

  StoreState copyWith({
    List<Producto>? productos,
    bool? cargando,
    String? error,
  }) {
    return StoreState(
      productos: productos ?? this.productos,
      cargando: cargando ?? this.cargando,
      error: error,
    );
  }
}

class StoreNotifier extends StateNotifier<StoreState> {
  final ApiClient _api;
  StoreNotifier(this._api) : super(const StoreState()) {
    cargar();
  }

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, error: null);
    try {
      final data = await _api.getList('/store/productos');
      state = state.copyWith(
        productos: data.map((j) => Producto.fromJson(j)).toList(),
        cargando: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(cargando: false, error: e.message);
    }
  }

  Future<String?> crearProducto({
    required String nombre,
    required double precioCompra,
    required double precioVenta,
    required int stock,
    int? stockMinimo,
    String? categoria,
    String? descripcion,
  }) async {
    try {
      await _api.post('/store/productos', body: {
        'nombre': nombre,
        'precioCompra': precioCompra,
        'precioVenta': precioVenta,
        'stock': stock,
        if (stockMinimo != null) 'stockMinimo': stockMinimo,
        if (categoria != null && categoria.isNotEmpty) 'categoria': categoria,
        if (descripcion != null && descripcion.isNotEmpty)
          'descripcion': descripcion,
      });
      await cargar();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> actualizarProducto(
    String id, {
    required String nombre,
    required double precioCompra,
    required double precioVenta,
    int? stockMinimo,
    String? categoria,
    String? descripcion,
  }) async {
    try {
      await _api.patch('/store/productos/$id', body: {
        'nombre': nombre,
        'precioCompra': precioCompra,
        'precioVenta': precioVenta,
        'stockMinimo': stockMinimo,
        'categoria': categoria,
        'descripcion': descripcion,
      });
      await cargar();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> eliminarProducto(String id) async {
    try {
      await _api.delete('/store/productos/$id');
      await cargar();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  /// items: [{productoId, cantidad}]
  Future<String?> crearVenta(
    List<Map<String, dynamic>> items,
    String metodoPago,
  ) async {
    try {
      await _api.post('/store/ventas', body: {
        'items': items,
        'metodoPago': metodoPago,
      });
      await cargar(); // refresca stock
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

final storeProvider = StateNotifierProvider<StoreNotifier, StoreState>((ref) {
  return StoreNotifier(ref.watch(apiClientProvider));
});
