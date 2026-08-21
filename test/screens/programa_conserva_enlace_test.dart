import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_app/domain/models/program_model.dart';

/// 🔴 La propiedad que hay que preservar: lo que identifica al producto en la
/// tienda —su id y su enlace— tiene que sobrevivir al viaje de la lista al
/// detalle.
///
/// La pantalla de programas no pasa el objeto que llega del GraphQL: construye
/// una tarjeta para pintar y, al abrir el detalle, **reconstruye** un
/// GraphqlProgram a partir de ella para añadirle textos de marketing. Hasta el
/// 2026-08-20 esa copia nacía sin `url` y con un id inventado desde el título,
/// así que «Inscribirme en LSO» avisaba de que no podía abrir la página.
///
/// Esta prueba fija la regla sobre el modelo: un programa reconstruido sin
/// enlace no sirve para inscribirse.
void main() {
  GraphqlProgram deLaTienda() => GraphqlProgram.fromJson({
    'id': 'cG9zdDo4NDc=',
    'name': 'Next Generation ¿Empresario o Emprendedor?',
    'link': 'https://lso.school/programas/next-generation-empresario-o-emprendedor/',
    'price': '\$300',
  });

  test('el producto de la tienda trae id y enlace', () {
    final p = deLaTienda();
    expect(p.id, 'cG9zdDo4NDc=');
    expect(p.url, contains('next-generation'));
  });

  test('una copia que conserva ambos sigue sirviendo para inscribirse', () {
    final original = deLaTienda();

    // Lo que hace la pantalla al abrir el detalle: rehacer el modelo añadiendo
    // textos propios, conservando lo que no puede inventarse.
    final copia = GraphqlProgram(
      id: original.id,
      name: original.name,
      url: original.url,
      description: 'Texto de marketing de la app',
      price: original.price,
    );

    expect(copia.url, original.url, reason: 'el enlace es lo que abre la tienda');
    expect(copia.id, original.id, reason: 'el id no se inventa desde el título');
    expect(copia.precioConMoneda, 'USD \$300');
  });

  test('una copia sin enlace no puede abrir nada, y por eso no vale', () {
    // Es exactamente lo que ocurría: el detalle recibía esto.
    final rota = GraphqlProgram(
      id: 'next-generation-empresario-o-emprendedor',
      name: 'Next Generation ¿Empresario o Emprendedor?',
      price: '\$300',
    );

    expect(rota.url, isNull);
    expect(rota.id, isNot('cG9zdDo4NDc='),
        reason: 'el id inventado desde el título tampoco identifica el producto');
  });
}
