import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_app/domain/utils/formato_telefono.dart';

/// `TextInputType.phone` elige el teclado que se ofrece, **no lo que se
/// acepta**: con un teclado predictivo, uno fisico, un pegado desde el
/// portapapeles o la app en web, un telefono acaba con letras dentro y nadie lo
/// nota hasta que hay que llamar a esa persona. Los tres formularios que piden
/// telefono —registro, asesoria y el pago de un evento— comparten este filtro;
/// hasta el 2026-08-26 solo lo tenia el registro.

/// Escribe [nuevo] sobre un campo vacio pasando por los formateadores, tal como
/// hace el campo de texto.
String filtrar(String nuevo) {
  var valor = TextEditingValue.empty;
  for (final f in formateadoresDeTelefono) {
    valor = f.formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(
        text: nuevo,
        selection: TextSelection.collapsed(offset: nuevo.length),
      ),
    );
  }
  return valor.text;
}

void main() {
  group('formateadoresDeTelefono', () {
    test('deja pasar un telefono normal', () {
      expect(filtrar('+57 300 123 4567'), '+57 300 123 4567');
    });

    test('deja el indicativo entre parentesis y los guiones', () {
      expect(filtrar('(57) 300-123-4567'), '(57) 300-123-4567');
    });

    test('quita las letras', () {
      expect(filtrar('300abc1234'), '3001234');
    });

    test('quita un texto pegado por error', () {
      // El caso real: se pega el nombre del contacto en vez del numero.
      expect(filtrar('Juan Perez'), ' ');
    });

    test('quita los signos que no son de un telefono', () {
      expect(filtrar(r'300@#$%123'), '300123');
    });

    test('no es digitsOnly: el ejemplo del propio campo lleva + y espacios', () {
      // Si alguien lo cambia a digitsOnly, este caso lo avisa.
      expect(filtrar('+57 300'), '+57 300');
    });
  });
}
