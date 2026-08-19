import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_app/domain/models/book_model.dart';
import 'package:legacy_app/domain/utils/abrir_en_lso.dart';

/// Los libros son de LSO igual que los programas: se publican en dólares y se
/// compran en su tienda. Dejaron de ir al carrito el 2026-08-19, que los sumaba
/// como pesos y les aplicaba IVA colombiano.
void main() {
  GraphqlBook deJson(Map<String, dynamic> json) => GraphqlBook.fromJson({
    'id': '1',
    'name': 'Trampas de las Familias Empresarias',
    'stockStatus': 'IN_STOCK',
    ...json,
  });

  group('el libro trae su página de la tienda', () {
    test('lee el campo link del producto', () {
      final l = deJson({
        'link': 'https://lso.school/libros/trampas-de-las-familias-empresarias/',
      });
      expect(
        l.url,
        'https://lso.school/libros/trampas-de-las-familias-empresarias/',
      );
    });

    test('sin enlace queda en null y la pantalla lo dice', () {
      expect(deJson({}).url, isNull);
      expect(deJson({'link': null}).url, isNull);
      expect(deJson({'link': ''}).url, isNull);
      expect(deJson({'link': '   '}).url, isNull);
    });

    test('el resto de la ficha se sigue leyendo', () {
      final l = deJson({'link': 'https://lso.school/libros/x/', 'price': '\$45'});
      expect(l.name, 'Trampas de las Familias Empresarias');
      expect(l.price, '\$45');
      expect(l.stockStatus, 'IN_STOCK');
    });
  });

  group('abrirEnLso', () {
    // Sin enlace ni siquiera se intenta abrir nada: devuelve false y quien
    // llama muestra el aviso, en vez de dejar el toque mudo.
    test('sin url no intenta abrir y avisa que no pudo', () async {
      expect(await abrirEnLso(null), isFalse);
      expect(await abrirEnLso(''), isFalse);
      expect(await abrirEnLso('   '), isFalse);
    });

    test('el mensaje nombra el sitio para poder buscarlo a mano', () {
      expect(mensajeLsoNoAbre, contains('lso.school'));
    });
  });
}
