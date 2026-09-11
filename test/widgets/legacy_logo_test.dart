import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:legacy_app/presentation/widgets/common/legacy_logo.dart';

/// El logo se sirve desde `assets/images/brand/`. Si un archivo falta o se
/// renombra, la app no falla al compilar: simplemente deja un hueco en la
/// pantalla. Esta prueba recorre las nueve combinaciones para que ese error
/// salga aqui y no en produccion.
void main() {
  testWidgets('todas las variantes del logo cargan su SVG', (tester) async {
    for (final variante in LegacyLogoVariante.values) {
      for (final tinta in LegacyLogoTinta.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              backgroundColor: const Color(0xFF162540),
              body: Center(
                child: LegacyLogo(variante: variante, tinta: tinta, height: 80),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byType(SvgPicture),
          findsOneWidget,
          reason: 'no se dibujo $variante/$tinta',
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'fallo al cargar $variante/$tinta',
        );
      }
    }
  });

  testWidgets('el atajo .simbolo admite una tinta plana', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: LegacyLogo.simbolo(height: 18, color: Color(0xFF9FB2C2)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect(svg.colorFilter, isNotNull);
    expect(tester.takeException(), isNull);
  });
}
