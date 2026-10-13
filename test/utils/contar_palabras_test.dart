import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_app/domain/utils/contar_palabras.dart';

void main() {
  test('cuenta palabras separadas por espacios y saltos de línea', () {
    expect(contarPalabras(''), 0);
    expect(contarPalabras('   '), 0);
    expect(contarPalabras('Hola'), 1);
    expect(contarPalabras('  Somos una   familia\nempresaria  '), 4);
  });
}
