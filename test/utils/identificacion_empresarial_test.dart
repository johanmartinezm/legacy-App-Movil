import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_app/domain/utils/identificacion_empresarial.dart';

void main() {
  group('paisesLatam', () {
    test('incluye Colombia primero y Otro al final', () {
      expect(paisesLatam.first, 'Colombia');
      expect(paisesLatam.last, 'Otro');
    });

    test('no tiene países repetidos', () {
      expect(paisesLatam.toSet().length, paisesLatam.length);
    });
  });

  group('tiposIdentificacionPara', () {
    test('Colombia ofrece NIT para la empresa, no solo documentos de persona', () {
      expect(tiposIdentificacionPara('Colombia'), contains('NIT'));
    });

    test('cada país LATAM (menos Otro) tiene su propio documento tributario', () {
      // Antes de este fix, cualquier país que no fuera Colombia caía en el
      // mismo genérico de "Pasaporte, Documento extranjero, Otro" sin ningún
      // documento de empresa real.
      final generico = tiposIdentificacionPara('Otro');
      for (final pais in paisesLatam.where((p) => p != 'Otro')) {
        expect(
          tiposIdentificacionPara(pais),
          isNot(equals(generico)),
          reason: '$pais no debería caer en la lista genérica',
        );
      }
    });

    test('un país no reconocido cae en el genérico, sin romper', () {
      expect(
        tiposIdentificacionPara('País inventado'),
        ['Pasaporte', 'Documento extranjero', 'Otro'],
      );
    });
  });
}
