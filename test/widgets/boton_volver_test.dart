import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_app/presentation/widgets/boton_volver.dart';

/// La flecha es una sola en toda la app desde el 2026-09-02: si alguien vuelve
/// a dibujar la suya, estas pruebas no lo ven, pero al menos fijan cómo se ve
/// la compartida.
void main() {
  testWidgets('siempre el mismo icono, color y tamaño', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: BotonVolver())),
    );

    final icono = tester.widget<Icon>(find.byType(Icon));
    expect(icono.icon, Icons.arrow_back_ios_new);
    expect(icono.color, Colors.white);
    expect(icono.size, 16);
  });

  testWidgets('el área que responde al dedo es mayor que el círculo',
      (tester) async {
    // El círculo mide 32 y eso se queda corto para un dedo; lo que se toca son
    // 44, que es el mínimo cómodo.
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: BotonVolver())),
    );

    expect(tester.getSize(find.byType(BotonVolver)).width, 44);
    expect(tester.getSize(find.byType(BotonVolver)).height, 44);
  });

  testWidgets('con onTap manda lo que le pasen', (tester) async {
    var tocado = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: BotonVolver(onTap: () => tocado = true)),
      ),
    );

    await tester.tap(find.byType(BotonVolver));
    expect(tocado, isTrue);
  });

  testWidgets('se anuncia como botón para los lectores de pantalla',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: BotonVolver())),
    );

    expect(
      tester.getSemantics(find.byType(BotonVolver).first),
      // InkResponse añade el foco por su cuenta; lo que importa aquí es que se
      // anuncie como botón y con nombre.
      matchesSemantics(
        label: 'Volver',
        isButton: true,
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
  });
}
