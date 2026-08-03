import 'package:flutter/material.dart';
import '../models/cart_item.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [
    // Mock Data for initial design review
    CartItem(
      id: '1',
      title: 'Programa: Gestión Patrimonial',
      type: 'Programa Educativo',
      price: 299.00,
    ),
    CartItem(
      id: '2',
      title: 'Asesoría Legal',
      type: 'Asesoría (1 hora)',
      price: 200.00,
    ),
    CartItem(
      id: '3',
      title: 'SUMMIT Legacy 2025',
      type: 'Evento | 10-12 Nov 2025',
      price: 299.00,
    ),
  ];

  List<CartItem> get items => _items;

  int get itemCount => _items.length;

  double get subtotal => _items.fold(0, (sum, item) => sum + item.price);

  double get iva => subtotal * 0.19;

  double get total => subtotal + iva;

  void addItem(CartItem item) {
    _items.add(item);
    notifyListeners();
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
