import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../api/api_service.dart';

class CartItem {
  final int id;
  final String nombre;
  final double precio;
  final String imagen;
  int cantidad;
  String nota;

  CartItem({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.imagen,
    this.cantidad = 1,
    this.nota = "",
  });

  Map<String, dynamic> toJson() {
    return {
      "id_plato": id,
      "cantidad": cantidad,
      "nota": nota,
    };
  }
}

class CartState extends ChangeNotifier {
  // 🛒 Cart Items List
  final List<CartItem> _items = [];

  // Delivery Parameters
  String _metodo = 'delivery'; // 'delivery' or 'retirar'
  String _telefono = '';
  String _direccion = '';
  String _latitud = '';
  String _longitud = '';
  String _nota = '';
  double _costoDelivery = 0.00;

  // Payment parameters
  String _pagoMetodo = 'pago_movil'; // 'pago_movil', 'transferencia', 'efectivo'
  String _pagoBanco = '';
  String _pagoReferencia = '';
  String _pagoMonto = '';

  bool _isLoading = false;

  List<CartItem> get items => _items;
  String get metodo => _metodo;
  String get telefono => _telefono;
  String get direccion => _direccion;
  String get latitud => _latitud;
  String get longitud => _longitud;
  String get nota => _nota;
  double get costoDelivery => _costoDelivery;

  String get pagoMetodo => _pagoMetodo;
  String get pagoBanco => _pagoBanco;
  String get pagoReferencia => _pagoReferencia;
  String get pagoMonto => _pagoMonto;

  bool get isLoading => _isLoading;

  int get totalItems => _items.fold(0, (sum, item) => sum + item.cantidad);
  double get totalComida => _items.fold(0.0, (sum, item) => sum + (item.precio * item.cantidad));
  double get totalPrice => totalComida + _costoDelivery;

  // Load client saved delivery details on login / profile load
  void setClientDetails(Map<String, dynamic> profile) {
    _telefono = profile['telefono'] ?? '';
    _direccion = profile['direccion'] ?? '';
    _latitud = profile['latitud'] ?? '';
    _longitud = profile['longitud'] ?? '';
    _nota = profile['notas'] ?? '';
    calculateDeliveryFee();
    notifyListeners();
  }

  void setMetodo(String value) {
    _metodo = value;
    calculateDeliveryFee();
    notifyListeners();
  }

  void setTelefono(String value) {
    _telefono = value;
    notifyListeners();
  }

  void setDireccion(String value) {
    _direccion = value;
    notifyListeners();
  }

  void setCoordinates(String lat, String lng) {
    _latitud = lat;
    _longitud = lng;
    calculateDeliveryFee();
    notifyListeners();
  }

  void setNota(String value) {
    _nota = value;
    notifyListeners();
  }

  void setPagoMetodo(String value) {
    _pagoMetodo = value;
    notifyListeners();
  }

  void setPagoBanco(String value) {
    _pagoBanco = value;
    notifyListeners();
  }

  void setPagoReferencia(String value) {
    _pagoReferencia = value;
    notifyListeners();
  }

  void setPagoMonto(String value) {
    _pagoMonto = value;
    notifyListeners();
  }

  /// Calculates delivery fee based on GPS distance
  void calculateDeliveryFee() {
    if (_metodo == 'retirar') {
      _costoDelivery = 0.00;
      notifyListeners();
      return;
    }

    if (_latitud.isEmpty || _longitud.isEmpty) {
      _costoDelivery = 0.00;
      notifyListeners();
      return;
    }

    try {
      final double clientLat = double.parse(_latitud);
      final double clientLng = double.parse(_longitud);

      // Hardcoded defaults matching backend
      const double restLat = 10.3392;
      const double restLng = -68.7428;
      const double ratePerKm = 1.50; // Cost per kilometer

      final double distance = Geolocator.distanceBetween(restLat, restLng, clientLat, clientLng) / 1000.0;
      _costoDelivery = double.parse((distance * ratePerKm).toStringAsFixed(2));
    } catch (e) {
      _costoDelivery = 0.00;
    }
    notifyListeners();
  }

  // ============ CART ACTIONS ============

  void addToCart({
    required int id,
    required String nombre,
    required double precio,
    required String imagen,
  }) {
    final existingIndex = _items.indexWhere((item) => item.id == id);
    if (existingIndex >= 0) {
      _items[existingIndex].cantidad++;
    } else {
      _items.add(
        CartItem(id: id, nombre: nombre, precio: precio, imagen: imagen),
      );
    }
    notifyListeners();
  }

  void incrementQuantity(int id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _items[index].cantidad++;
      notifyListeners();
    }
  }

  void decrementQuantity(int id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      if (_items[index].cantidad > 1) {
        _items[index].cantidad--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void removeItem(int id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void setItemNote(int id, String note) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _items[index].nota = note;
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    _pagoBanco = '';
    _pagoReferencia = '';
    _pagoMonto = '';
    notifyListeners();
  }

  /// Submit delivery order to backend REST API
  Future<Map<String, dynamic>> submitOrder() async {
    if (_items.isEmpty) {
      return {"success": false, "message": "El carrito está vacío."};
    }

    _isLoading = true;
    notifyListeners();

    final payloadItems = _items.map((item) => item.toJson()).toList();
    
    final result = await ApiService.submitClientOrder(
      metodo: _metodo,
      telefono: _telefono,
      direccion: _direccion,
      latitud: _latitud,
      longitud: _longitud,
      nota: _nota,
      items: payloadItems,
      pagoMetodo: _pagoMetodo,
      pagoBanco: _pagoBanco,
      pagoReferencia: _pagoReferencia,
      pagoMonto: _pagoMonto.isEmpty ? totalComida.toStringAsFixed(2) : _pagoMonto,
    );

    if (result['success']) {
      clearCart();
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }
}
