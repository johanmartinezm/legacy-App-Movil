import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_app/domain/models/content_model.dart';
import 'package:legacy_app/domain/utils/ultimo_estreno.dart';

/// El banner «Estreno semanal» de Legacy Knowledge enseña lo más reciente de
/// las tres fuentes, comparando la fecha AAAA-MM-DD que trae cada una.
void main() {
  ContentItem item(String id, String? date, {String type = 'article'}) =>
      ContentItem(
        id: id,
        title: 'Título $id',
        type: type,
        category: '',
        isFree: true,
        imageUrl: '',
        date: date,
      );

  group('ultimoEstreno', () {
    test('elige el de fecha más reciente, venga de donde venga', () {
      final r = ultimoEstreno([
        item('propio', '2026-10-01'),
        item('youtube', '2026-10-12', type: 'video'),
        item('wordpress', '2026-09-30'),
      ]);
      expect(r!.id, 'youtube');
    });

    test('lo que no tiene fecha no compite (los libros)', () {
      final r = ultimoEstreno([
        item('libro', null, type: 'book'),
        item('vacío', '  '),
        item('articulo', '2026-01-05'),
      ]);
      expect(r!.id, 'articulo');
    });

    test('con empate de fecha gana el primero de la lista', () {
      final r = ultimoEstreno([
        item('propio', '2026-10-12'),
        item('youtube', '2026-10-12', type: 'video'),
      ]);
      expect(r!.id, 'propio');
    });

    test('sin nada fechado no hay estreno', () {
      expect(ultimoEstreno([]), isNull);
      expect(ultimoEstreno([item('libro', null, type: 'book')]), isNull);
      expect(ultimoEstreno([item('roto', 'no-es-fecha')]), isNull);
    });
  });

  test('fechaCortaEstreno', () {
    expect(fechaCortaEstreno('2026-10-13'), '13 oct');
    expect(fechaCortaEstreno('2026-01-05'), '5 ene');
    expect(fechaCortaEstreno(null), '');
    expect(fechaCortaEstreno('ayer'), '');
  });

  test('tipoEstreno', () {
    expect(tipoEstreno(item('a', null, type: 'video')), 'Video');
    expect(tipoEstreno(item('a', null, type: 'podcast')), 'Podcast');
    expect(tipoEstreno(item('a', null, type: 'article')), 'Artículo');
    expect(tipoEstreno(item('a', null, type: '')), 'Artículo');
  });
}
