import 'package:flutter/material.dart';
import '../models/cart_item.dart';

/// El carrito guarda **un solo elemento**: se compra de uno en uno, por
/// decisión del 2026-08-19.
///
/// Hasta esa fecha admitía una lista y además arrancaba con tres artículos de
/// prueba dentro —«Programa: Gestión Patrimonial», «Asesoría Legal» y «SUMMIT
/// Legacy 2025»—, así que cualquiera que abriera el carrito se encontraba con
/// una compra de 798 que no había pedido.
class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  int get itemCount => _items.length;

  /// Lo que hay en el carrito, o null si está vacío.
  CartItem? get item => _items.isEmpty ? null : _items.first;

  double get subtotal => _items.fold(0, (sum, item) => sum + item.price);

  double get iva => subtotal * 0.19;

  double get total => subtotal + iva;

  /// Deja [item] como el único elemento del carrito.
  ///
  /// Devuelve lo que había antes —null si estaba vacío— para que la pantalla
  /// pueda decirlo. Sustituir en silencio dejaría a alguien pagando algo
  /// distinto de lo que acaba de elegir, que es peor que negarse a añadirlo.
  CartItem? addItem(CartItem item) {
    final anterior = _items.isEmpty ? null : _items.first;
    _items
      ..clear()
      ..add(item);
    notifyListeners();
    return anterior;
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
