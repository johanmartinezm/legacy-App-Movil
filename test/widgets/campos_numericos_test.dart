import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_app/presentation/widgets/custom_text_field.dart';

/// `keyboardType` **no restringe** lo que se puede escribir: solo sugiere un
/// teclado. En Android se pasa a las letras con una tecla, y un teclado físico o
/// un pegado lo saltan del todo. Por eso el documento admitía letras aunque
/// pidiera teclado numérico.
///
/// Estas pruebas escriben en el campo como lo haría una persona —incluido el
/// caso del pegado, que es el que ningún teclado filtra—.
void main() {
  Future<void> montar(
    WidgetTester tester, {
    required TextEditingController controlador,
    required List<TextInputFormatter> filtros,
    required TextInputType teclado,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomTextField(
            label: 'Campo',
            controller: controlador,
            keyboardType: teclado,
            inputFormatters: filtros,
          ),
        ),
      ),
    );
  }

  group('número de identificación', () {
    testWidgets('descarta las letras y deja los dígitos', (tester) async {
      final controlador = TextEditingController();
      await montar(
        tester,
        controlador: controlador,
        filtros: [FilteringTextInputFormatter.digitsOnly],
        teclado: TextInputType.number,
      );

      await tester.enterText(find.byType(TextFormField), 'abc123def456');

      expect(controlador.text, '123456');
    });

    testWidgets('un pegado íntegro de letras deja el campo vacío', (
      tester,
    ) async {
      final controlador = TextEditingController();
      await montar(
        tester,
        controlador: controlador,
        filtros: [FilteringTextInputFormatter.digitsOnly],
        teclado: TextInputType.number,
      );

      await tester.enterText(find.byType(TextFormField), 'cédula');

      expect(controlador.text, isEmpty);
    });
  });

  group('teléfono', () {
    final filtros = [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-() ]')),
    ];

    testWidgets('conserva el formato internacional del propio ejemplo', (
      tester,
    ) async {
      final controlador = TextEditingController();
      await montar(
        tester,
        controlador: controlador,
        filtros: filtros,
        teclado: TextInputType.phone,
      );

      await tester.enterText(find.byType(TextFormField), '+57 300 123 4567');

      expect(controlador.text, '+57 300 123 4567');
    });

    testWidgets('acepta paréntesis y guiones, y quita las letras', (
      tester,
    ) async {
      final controlador = TextEditingController();
      await montar(
        tester,
        controlador: controlador,
        filtros: filtros,
        teclado: TextInputType.phone,
      );

      await tester.enterText(find.byType(TextFormField), '(601) 555-1234 ext');

      expect(controlador.text, '(601) 555-1234 ');
    });
  });

  testWidgets('sin filtros el campo no restringe nada', (tester) async {
    // El parámetro es opcional a propósito: el resto de campos —nombre, empresa,
    // cargo— tienen que seguir aceptando texto libre con tildes y eñes.
    final controlador = TextEditingController();
    await montar(
      tester,
      controlador: controlador,
      filtros: const [],
      teclado: TextInputType.text,
    );

    await tester.enterText(find.byType(TextFormField), 'Compañía Muñoz S.A.S.');

    expect(controlador.text, 'Compañía Muñoz S.A.S.');
  });
}
