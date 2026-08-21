import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 🔴 La propiedad que hay que preservar: a la Biblioteca se puede llegar.
///
/// La ruta `/libros` existía desde el commit inicial y la pantalla estaba
/// completa —cinco libros con precio, imagen y enlace a la tienda—, pero
/// **ninguna pantalla enlazaba a ella**. El único camino era escribirle «libro»
/// al asistente, que responde con un enlace interno. Se descubrió al intentar
/// probarla el 2026-08-20: no había forma de abrirla.
///
/// Esta prueba mira el código fuente en vez de pintar nada, porque lo que se
/// perdió no fue un widget sino la existencia de un camino.
void main() {
  test('alguna pantalla navega a /libros', () {
    final enlaces = <String>[];
    for (final f in Directory('lib/presentation').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final texto = f.readAsStringSync();
      if (texto.contains("push('/libros')") || texto.contains("go('/libros')")) {
        enlaces.add(f.path.split(RegExp(r'[\/]')).last);
      }
    }

    expect(
      enlaces,
      isNotEmpty,
      reason: 'la Biblioteca existe pero no se puede alcanzar desde ninguna pantalla',
    );
  });

  test('la entrada está en la sección de LSO', () {
    // Decisión del cliente del 2026-08-20: los libros salen de la misma tienda
    // que los programas, así que se buscan ahí.
    final lso = File('lib/presentation/screens/programs/programs_screen.dart')
        .readAsStringSync();

    expect(lso.contains("push('/libros')"), isTrue,
        reason: 'la sección de LSO debe llevar a la biblioteca');
    expect(lso.contains('Biblioteca'), isTrue);
  });
}
