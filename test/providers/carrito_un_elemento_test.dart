import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_app/domain/models/cart_item.dart';
import 'package:legacy_app/domain/providers/cart_provider.dart';

CartItem articulo(String id, {String? titulo, double precio = 100}) => CartItem(
  id: id,
  title: titulo ?? 'Artículo $id',
  type: 'Programa Educativo',
  price: precio,
);

void main() {
  group('el carrito empieza vacío', () {
    // Hasta el 2026-08-19 traía tres artículos de prueba dentro, así que quien
    // abriera el carrito se encontraba una compra de 798 que no había pedido.
    test('no hay nada dentro al arrancar', () {
      final carrito = CartProvider();
      expect(carrito.items, isEmpty);
      expect(carrito.itemCount, 0);
      expect(carrito.item, isNull);
      expect(carrito.subtotal, 0);
      expect(carrito.total, 0);
    });
  });

  group('solo un elemento por compra', () {
    test('el primero entra y no desplaza a nadie', () {
      final carrito = CartProvider();
      final anterior = carrito.addItem(articulo('1'));

      expect(anterior, isNull);
      expect(carrito.itemCount, 1);
      expect(carrito.item!.id, '1');
    });

    test('el segundo sustituye al primero y dice a quién sacó', () {
      final carrito = CartProvider();
      carrito.addItem(articulo('1', titulo: 'Gobierno Corporativo'));
      final anterior = carrito.addItem(articulo('2', titulo: 'Negociación'));

      expect(carrito.itemCount, 1, reason: 'el carrito es de un elemento');
      expect(carrito.item!.title, 'Negociación');
      expect(anterior, isNotNull);
      expect(anterior!.title, 'Gobierno Corporativo');
    });

    test('añadir diez deja uno', () {
      final carrito = CartProvider();
      for (var i = 0; i < 10; i++) {
        carrito.addItem(articulo('$i'));
      }
      expect(carrito.itemCount, 1);
      expect(carrito.item!.id, '9');
    });

    test('volver a añadir el mismo no cuenta como sustitución', () {
      // La pantalla usa esto para no decir «se cambió X por X».
      final carrito = CartProvider();
      carrito.addItem(articulo('1'));
      final anterior = carrito.addItem(articulo('1'));

      expect(anterior!.id, '1');
      expect(carrito.itemCount, 1);
    });

    test('el total corresponde solo a lo que queda dentro', () {
      final carrito = CartProvider();
      carrito.addItem(articulo('1', precio: 300));
      carrito.addItem(articulo('2', precio: 100));

      expect(carrito.subtotal, 100, reason: 'el de 300 ya no está');
      expect(carrito.iva, closeTo(19, 0.001));
      expect(carrito.total, closeTo(119, 0.001));
    });
  });

  group('quitar y vaciar', () {
    test('quitar el único elemento deja el carrito vacío', () {
      final carrito = CartProvider();
      carrito.addItem(articulo('1'));
      carrito.removeItem('1');

      expect(carrito.items, isEmpty);
      expect(carrito.item, isNull);
      expect(carrito.total, 0);
    });

    test('vaciar funciona con algo dentro', () {
      final carrito = CartProvider();
      carrito.addItem(articulo('1'));
      carrito.clearCart();

      expect(carrito.items, isEmpty);
    });
  });

  test('avisa a quien lo escucha en cada cambio', () {
    final carrito = CartProvider();
    var avisos = 0;
    carrito.addListener(() => avisos++);

    carrito.addItem(articulo('1'));
    carrito.addItem(articulo('2'));
    carrito.removeItem('2');
    carrito.clearCart();

    expect(avisos, 4);
  });
}
