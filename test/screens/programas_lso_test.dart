import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_app/domain/models/program_model.dart';
import 'package:legacy_app/presentation/screens/programs/programs_screen.dart';

/// Los programas de LSO salen de la lista del cliente del 2026-10-15, no de la
/// tienda: la tienda solo aporta imagen y precio cuando el producto existe.
void main() {
  final tienda = [
    GraphqlProgram(
      id: 'cert',
      // En la tienda tiene otro nombre: se encuentra por el enlace.
      name: 'Certificación en Gobierno Corporativo',
      url: 'https://lso.school/programas/certificacion-en-gobierno-corporativo/',
      imageUrl: 'https://lso.school/cert.jpg',
      price: '2500',
    ),
    GraphqlProgram(
      id: 'juntas',
      name: 'Juntas, Consejos y Directorios que Crean Valor',
      url: 'https://lso.school/programas/juntas-consejos-y-directorios-que-crean-valor/',
      price: '300',
    ),
  ];

  test('las dos secciones traen la lista del cliente, en su orden', () {
    expect(programasPrincipales.map((p) => p.titulo), [
      'Programa de Formación para Familias Empresarias y Propietarios',
      'Certificación Internacional en Gobierno Corporativo',
      'Programa de Formación de Consultores en Empresa Familiar',
      'Programa Ejecutivo de Gobierno Corporativo para Empresas de Seguros',
    ]);
    expect(programasActualizacion, hasLength(5));
    expect(
      programasActualizacion.every((p) => p.enlace == 'https://lso.school/programas-de-actualizacion/'),
      isTrue,
    );
  });

  test('el título y el enlace son los del cliente; imagen y precio, de la tienda', () {
    final filas = armarProgramas(tienda, programasPrincipales);
    final (cert, enTienda) = filas[1];
    expect(cert.name, 'Certificación Internacional en Gobierno Corporativo');
    expect(cert.url, 'https://lso.school/programas/certificacion-en-gobierno-corporativo/');
    expect(cert.imageUrl, 'https://lso.school/cert.jpg');
    expect(cert.price, '2500');
    expect(enTienda, isTrue);
  });

  test('sin producto en la tienda, la tarjeta sale igual y con su enlace', () {
    final (consultores, enTienda) = armarProgramas(tienda, programasPrincipales)[2];
    expect(consultores.url, 'https://lso.school/programas/consultores-en-empresa-familiar/');
    expect(consultores.price, isNull);
    expect(enTienda, isFalse);
  });

  test('los de actualización se cruzan por título, no por la página común', () {
    final filas = armarProgramas(tienda, programasActualizacion);
    // «Juntas…» existe con otras mayúsculas: aporta su precio pero lleva a la
    // página de actualización, que es la que dio el cliente.
    expect(filas[0].$2, isTrue);
    expect(filas[0].$1.price, '300');
    expect(filas[0].$1.url, 'https://lso.school/programas-de-actualizacion/');
    // El resto no está en la tienda; ninguno se lleva un producto ajeno.
    expect(filas.skip(1).every((f) => !f.$2), isTrue);
  });

  test('sin imagen en el producto del enlace, la toma del que tiene su título', () {
    final conDosProductos = [
      GraphqlProgram(
        id: 'enlace',
        name: 'Propietarios y Familias Empresarias',
        url: 'https://lso.school/programas/propietarios-y-familias-empresarias/',
        price: '1200',
      ),
      GraphqlProgram(
        id: 'titulo',
        name: 'Programa de Formación para Familias Empresarias y Propietarios',
        url: 'https://lso.school/programas/otro-enlace/',
        imageUrl: 'https://lso.school/familias.webp',
        price: '999',
      ),
    ];
    final (prop, enTienda) = armarProgramas(conDosProductos, programasPrincipales)[0];
    expect(prop.imageUrl, 'https://lso.school/familias.webp');
    // El precio y el enlace siguen siendo los del enlace del cliente.
    expect(prop.price, '1200');
    expect(prop.url, 'https://lso.school/programas/propietarios-y-familias-empresarias/');
    expect(enTienda, isTrue);
  });

  test('si la tienda no responde, siguen todas las tarjetas', () {
    expect(armarProgramas(const [], programasPrincipales), hasLength(4));
    expect(armarProgramas(const [], programasActualizacion), hasLength(5));
  });
}
