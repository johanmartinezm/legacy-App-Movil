import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_app/domain/models/content_model.dart';

ContentItem _conTipo(String tipo) => ContentItem(
      id: '1',
      title: 'Contenido',
      type: tipo,
      category: 'Knowledge',
      isFree: true,
      imageUrl: '',
    );

void main() {
  group('ContentItem.esVideo (el play de favoritos)', () {
    test('reconoce el tipo con que llegan los videos, en minúscula', () {
      expect(_conTipo('video').esVideo, isTrue);
    });

    test('reconoce también otras formas guardadas', () {
      expect(_conTipo('Video').esVideo, isTrue);
      expect(_conTipo(' VIDEO ').esVideo, isTrue);
    });

    test('un artículo o un libro no son video', () {
      expect(_conTipo('article').esVideo, isFalse);
      expect(_conTipo('book').esVideo, isFalse);
      expect(_conTipo('').esVideo, isFalse);
    });
  });
}
