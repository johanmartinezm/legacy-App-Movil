import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_app/data/config/documentos_legales.dart';
import 'package:legacy_app/presentation/screens/legal_notice_screen.dart';
import 'package:legacy_app/presentation/widgets/documentos_legales_enlaces.dart';

/// Las dos tiendas exigen que los documentos legales sean alcanzables desde la
/// app. Un enlace que apunta a otra parte pasa desapercibido en una revisión
/// visual y se descubre en la de Apple.
void main() {
  group('las URL son las publicadas', () {
    test('los términos apuntan al documento de la app, no al de la web', () {
      expect(
        DocumentosLegales.terminos,
        'https://legacynetworkco.com/terminos-y-condiciones-de-uso-app-legacy/',
      );
    });

    test('la política apunta al documento vigente', () {
      expect(
        DocumentosLegales.privacidad,
        'https://legacynetworkco.com/politica-de-privacidad/',
      );
    });

    test('las dos son https', () {
      for (final url in [
        DocumentosLegales.terminos,
        DocumentosLegales.privacidad,
      ]) {
        expect(Uri.parse(url).scheme, 'https');
      }
    });
  });

  testWidgets('los dos enlaces se pintan', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DocumentosLegalesEnlaces()),
      ),
    );

    expect(find.byKey(const Key('enlace-terminos')), findsOneWidget);
    expect(find.byKey(const Key('enlace-privacidad')), findsOneWidget);
  });

  testWidgets('los avisos legales advierten de que son un resumen', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LegalNoticeScreen()));

    // El texto embebido son tres secciones frente a las dieciséis del documento
    // real: presentarlo como el contrato completo sería engañoso.
    expect(find.textContaining('Este es un resumen'), findsOneWidget);
    expect(find.byType(DocumentosLegalesEnlaces), findsOneWidget);
  });
}
