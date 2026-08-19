import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_app/domain/models/program_model.dart';

/// Los programas salen de la tienda de LSO, que publica en dólares y devuelve
/// la cifra sin decir de qué moneda. En la app conviven con eventos en pesos
/// colombianos, así que un «$300» suelto se lee como trescientos pesos.
///
/// Las cadenas de aquí son las que devuelve hoy lso.school/graphql.
GraphqlProgram programa({String? precio}) => GraphqlProgram(
  id: '1',
  name: 'Certificación Internacional en Gobierno Corporativo',
  price: precio,
);

void main() {
  group('precioConMoneda', () {
    test('antepone la moneda a la cifra de la tienda', () {
      expect(programa(precio: '\$300').precioConMoneda, 'USD \$300');
      expect(programa(precio: '\$1.100').precioConMoneda, 'USD \$1.100');
      expect(programa(precio: '\$2.500').precioConMoneda, 'USD \$2.500');
    });

    test('sin precio no inventa una moneda', () {
      // Tres de los catorce programas publicados llegan así; la tarjeta los
      // muestra como «Cotización».
      expect(programa(precio: null).precioConMoneda, isNull);
      expect(programa(precio: '').precioConMoneda, isNull);
      expect(programa(precio: '   ').precioConMoneda, isNull);
    });

    test('no duplica la moneda ni deja espacios sueltos', () {
      expect(programa(precio: ' \$300 ').precioConMoneda, 'USD \$300');
    });
  });

  group('url: la pagina del programa en LSO', () {
    // La inscripción se hace en la tienda de LSO, no en la app, así que el
    // enlace es lo único que hace falta del producto además de su ficha.
    GraphqlProgram deJson(Map<String, dynamic> json) =>
        GraphqlProgram.fromJson({'id': '1', 'name': 'Programa', ...json});

    test('lee el campo link del producto', () {
      final p = deJson({
        'link': 'https://lso.school/programas/next-generation-empresario-o-emprendedor/',
      });
      expect(
        p.url,
        'https://lso.school/programas/next-generation-empresario-o-emprendedor/',
      );
    });

    test('sin enlace queda en null y la pantalla lo dice', () {
      expect(deJson({}).url, isNull);
      expect(deJson({'link': null}).url, isNull);
      expect(deJson({'link': ''}).url, isNull);
      expect(deJson({'link': '   '}).url, isNull);
    });
  });

  group('priceValue: lo que quedo del carrito', () {
    test('extrae el número de la cifra publicada', () {
      expect(programa(precio: '\$300').priceValue, 300);
      expect(programa(precio: '\$2.500').priceValue, 2500);
    });

    test('sin precio vale cero', () {
      expect(programa(precio: null).priceValue, 0);
    });
  });
}
