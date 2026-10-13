import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_app/domain/utils/indicativos.dart';

void main() {
  test('Colombia va primero', () {
    expect(indicativos.first.pais, 'Colombia');
    expect(indicativos.first.codigo, '+57');
  });

  test('todos los códigos empiezan por + y no se repite ningún país', () {
    for (final i in indicativos) {
      expect(i.codigo, matches(RegExp(r'^\+\d{1,4}$')), reason: i.pais);
    }
    final paises = indicativos.map((i) => i.pais).toList();
    expect(paises.toSet().length, paises.length);
  });

  test('numeroLocalValido cuenta dígitos, no separadores', () {
    expect(numeroLocalValido('300 123 4567'), isTrue);
    expect(numeroLocalValido('(601) 555-1234'), isTrue);
    expect(numeroLocalValido('12345'), isFalse);
    expect(numeroLocalValido('123 456 789 012 345'), isFalse);
  });

  test('telefonoCompleto une indicativo y número', () {
    expect(telefonoCompleto(indicativos.first, ' 300 123 4567 '), '+57 300 123 4567');
  });
}
