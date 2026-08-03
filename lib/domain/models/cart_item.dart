class CartItem {
  final String id;
  final String title;
  final String type; // e.g., 'Programa Educativo', 'Asesoría', 'Evento'
  final double price;

  CartItem({
    required this.id,
    required this.title,
    required this.type,
    required this.price,
  });
}
