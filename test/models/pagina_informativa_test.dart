import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_app/domain/models/pagina_informativa_model.dart';

void main() {
  group('parrafos', () {
    test('separa por linea en blanco', () {
      const pagina = PaginaInformativa(
        slug: 'x',
        titulo: 'X',
        cuerpo: 'Uno.\n\nDos.\n\nTres.',
      );

      expect(pagina.parrafos, ['Uno.', 'Dos.', 'Tres.']);
    });

    test('un salto de linea suelto no parte el parrafo', () {
      // Al escribir en el panel es normal cortar la linea a mano; solo la
      // linea en blanco marca un parrafo nuevo.
      const pagina = PaginaInformativa(
        slug: 'x',
        titulo: 'X',
        cuerpo: 'Una frase\ny su continuacion.',
      );

      expect(pagina.parrafos, ['Una frase\ny su continuacion.']);
    });

    test('tolera lineas en blanco de sobra y espacios al final', () {
      const pagina = PaginaInformativa(
        slug: 'x',
        titulo: 'X',
        cuerpo: '  Uno.  \n\n\n\n   \n\nDos.   \n\n\n',
      );

      expect(pagina.parrafos, ['Uno.', 'Dos.']);
    });

    test('un cuerpo vacio no da parrafos', () {
      const pagina = PaginaInformativa(slug: 'x', titulo: 'X', cuerpo: '   \n\n  ');

      expect(pagina.parrafos, isEmpty);
    });
  });

  test('fromJson acepta campos ausentes', () {
    // El backend siempre los manda, pero un 200 recortado no debe reventar la
    // pantalla: los opcionales caen a cadena vacia.
    final pagina = PaginaInformativa.fromJson({
      'slug': 'legacy-board',
      'titulo': 'Legacy Board',
    });

    expect(pagina.subtitulo, '');
    expect(pagina.imagenUrl, '');
    expect(pagina.cuerpo, '');
    expect(pagina.actualizadaEn, isNull);
  });
}
