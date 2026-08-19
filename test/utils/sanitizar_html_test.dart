import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_app/domain/utils/sanitizar_html.dart';

void main() {
  group('quita lo que no debe ejecutarse ni cargarse solo', () {
    test('script con su contenido', () {
      final salida = sanitizarHtml('<p>Hola</p><script>alert(1)</script>');
      expect(salida.toLowerCase(), isNot(contains('script')));
      expect(salida, isNot(contains('alert(1)')));
      expect(salida, contains('Hola'));
    });

    test('script sin cerrar, que no casa con el bloque completo', () {
      final salida = sanitizarHtml('<p>Hola</p><script src="http://ajeno/x.js">');
      expect(salida.toLowerCase(), isNot(contains('script')));
      expect(salida, contains('Hola'));
    });

    test('iframe, object y embed', () {
      for (final etiqueta in ['iframe', 'object', 'embed']) {
        final salida = sanitizarHtml('<p>Texto</p><$etiqueta src="http://ajeno"></$etiqueta>');
        expect(salida.toLowerCase(), isNot(contains(etiqueta)), reason: etiqueta);
        expect(salida, contains('Texto'));
      }
    });

    test('el contenido de un style no se queda suelto como texto', () {
      final salida = sanitizarHtml('<style>body{color:red}</style><p>Hola</p>');
      expect(salida, isNot(contains('color:red')));
      expect(salida, contains('Hola'));
    });

    test('atributos de evento', () {
      final salida = sanitizarHtml('<img src="foto.png" onerror="alert(1)">');
      expect(salida.toLowerCase(), isNot(contains('onerror')));
      expect(salida, contains('foto.png'));
    });

    test('atributo de evento con comilla simple y sin comillas', () {
      expect(sanitizarHtml("<div onclick='malo()'>x</div>").toLowerCase(), isNot(contains('onclick')));
      expect(sanitizarHtml('<div onclick=malo()>x</div>').toLowerCase(), isNot(contains('onclick')));
    });

    test('enlaces javascript: y vbscript:', () {
      expect(sanitizarHtml('<a href="javascript:alert(1)">clic</a>').toLowerCase(),
          isNot(contains('javascript:')));
      expect(sanitizarHtml('<a href="vbscript:algo">clic</a>').toLowerCase(),
          isNot(contains('vbscript:')));
    });

    test('formularios, que piden datos dentro del contenido', () {
      final salida = sanitizarHtml('<form action="http://ajeno"><input name="clave"></form>');
      expect(salida.toLowerCase(), isNot(contains('<form')));
      expect(salida.toLowerCase(), isNot(contains('<input')));
    });

    test('mayusculas y espacios raros no lo esquivan', () {
      expect(sanitizarHtml('<SCRIPT>alert(1)</SCRIPT>').toLowerCase(), isNot(contains('script')));
      expect(sanitizarHtml('< script >alert(1)< / script >').toLowerCase(),
          isNot(contains('alert(1)')));
    });
  });

  group('conserva lo que sirve para leer', () {
    test('parrafos, negritas, listas y saltos', () {
      const entrada = '<p>Un <strong>párrafo</strong></p><ul><li>uno</li></ul><br>';
      expect(sanitizarHtml(entrada), entrada);
    });

    test('un enlace normal', () {
      const entrada = '<a href="https://legacy.intelyclick.com">Legacy</a>';
      expect(sanitizarHtml(entrada), entrada);
    });

    test('una imagen normal', () {
      const entrada = '<img src="https://cdn.example.com/foto.png" alt="foto">';
      expect(sanitizarHtml(entrada), entrada);
    });

    test('texto plano sin etiquetas', () {
      expect(sanitizarHtml('Solo texto, sin nada raro.'), 'Solo texto, sin nada raro.');
    });

    test('acentos y emoji', () {
      const entrada = '<p>Sesión de bienvenida 🎉</p>';
      expect(sanitizarHtml(entrada), entrada);
    });
  });

  group('bordes', () {
    test('nulo y vacio devuelven cadena vacia', () {
      expect(sanitizarHtml(null), '');
      expect(sanitizarHtml(''), '');
    });

    test('es idempotente: sanear dos veces da lo mismo', () {
      const entrada = '<p>Hola</p><script>alert(1)</script><img src="x" onerror="y">';
      final unaVez = sanitizarHtml(entrada);
      expect(sanitizarHtml(unaVez), unaVez);
    });
  });
}
