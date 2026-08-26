import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_app/domain/utils/nombre_social.dart';

/// Google y Apple mandan el nombre completo en **una sola cadena** y el
/// formulario de registro pide nombre y apellido por separado.
///
/// Hasta el 2026-08-26 la primera palabra era el nombre y todo lo demas el
/// apellido. Con dos palabras funciona; con cuatro —dos nombres y dos
/// apellidos, que es lo normal aqui— no.
void main() {
  group('repartirNombre', () {
    test('dos palabras: una y una', () {
      final r = repartirNombre('Ana Restrepo');
      expect(r.nombre, 'Ana');
      expect(r.apellido, 'Restrepo');
    });

    test('cuatro palabras: dos y dos', () {
      // El caso que fallaba: quedaba «Johan» + «Yezid Martinez Melo».
      final r = repartirNombre('Johan Yezid Martinez Melo');
      expect(r.nombre, 'Johan Yezid');
      expect(r.apellido, 'Martinez Melo');
    });

    test('tres palabras: un nombre y dos apellidos', () {
      // Ambiguo de verdad —«Juan Carlos Pérez» se escribe igual— y se elige la
      // lectura comun entre quienes usan esta app.
      final r = repartirNombre('Ana Restrepo Gómez');
      expect(r.nombre, 'Ana');
      expect(r.apellido, 'Restrepo Gómez');
    });

    test('cinco palabras: dos y tres', () {
      final r = repartirNombre('Ana María Restrepo de Gómez');
      expect(r.nombre, 'Ana María');
      expect(r.apellido, 'Restrepo de Gómez');
    });

    test('seis palabras: tres y tres', () {
      final r = repartirNombre('María José Pérez de la Cruz');
      expect(r.nombre, 'María José Pérez');
      expect(r.apellido, 'de la Cruz');
    });

    test('una sola palabra deja el apellido vacio', () {
      // Inventarlo seria peor: el formulario lo pide obligatorio y quien se
      // registra lo completa.
      final r = repartirNombre('Cher');
      expect(r.nombre, 'Cher');
      expect(r.apellido, '');
    });

    test('cadena vacia no revienta', () {
      final r = repartirNombre('');
      expect(r.nombre, '');
      expect(r.apellido, '');
    });

    test('nulo no revienta', () {
      // Apple puede no mandar el nombre.
      final r = repartirNombre(null);
      expect(r.nombre, '');
      expect(r.apellido, '');
    });

    test('espacios de sobra no crean palabras vacias', () {
      final r = repartirNombre('  Ana   Restrepo  ');
      expect(r.nombre, 'Ana');
      expect(r.apellido, 'Restrepo');
    });

    test('solo espacios se comporta como vacio', () {
      final r = repartirNombre('   ');
      expect(r.nombre, '');
      expect(r.apellido, '');
    });
  });
}
