import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_app/domain/utils/perfil_desplegables.dart';

/// Guardar el perfil escribía «Segunda» y «Otro» a quien no tenía generación
/// ni sector (2026-11-10). Solo debe viajar el desplegable que se toque.
void main() {
  const generaciones = [sinEspecificar, 'Primera (Fundador)', 'Segunda'];

  group('valorParaDesplegable', () {
    test('vacío o nulo se muestra sin especificar', () {
      expect(valorParaDesplegable('', generaciones), sinEspecificar);
      expect(valorParaDesplegable(null, generaciones), sinEspecificar);
    });
    test('un valor de la lista se muestra tal cual', () {
      expect(valorParaDesplegable('Segunda', generaciones), 'Segunda');
    });
    test('un valor fuera de la lista no revienta el desplegable', () {
      expect(valorParaDesplegable('2da', generaciones), sinEspecificar);
    });
  });

  group('valorParaGuardar', () {
    test('sin tocar no viaja, aunque esté vacío en la base', () {
      expect(
          valorParaGuardar(guardado: '', elegido: sinEspecificar, tocado: false),
          isNull);
    });
    test('sin tocar no pisa un valor fuera de la lista', () {
      expect(
          valorParaGuardar(guardado: 'F', elegido: sinEspecificar, tocado: false),
          isNull);
    });
    test('tocado con un valor nuevo, viaja', () {
      expect(valorParaGuardar(guardado: '', elegido: 'Segunda', tocado: true),
          'Segunda');
    });
    test('tocado y dejado igual, no viaja', () {
      expect(
          valorParaGuardar(guardado: 'Segunda', elegido: 'Segunda', tocado: true),
          isNull);
    });
    test('tocado y puesto en sin especificar, se borra', () {
      expect(
          valorParaGuardar(
              guardado: 'Segunda', elegido: sinEspecificar, tocado: true),
          '');
    });
  });
}
