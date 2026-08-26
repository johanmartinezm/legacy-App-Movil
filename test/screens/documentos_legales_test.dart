import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_app/config/theme/app_theme.dart';
import 'package:legacy_app/data/config/documentos_legales.dart';
import 'package:legacy_app/presentation/screens/legal_notice_screen.dart';
import 'package:legacy_app/presentation/widgets/documentos_legales_enlaces.dart';

/// Contraste según WCAG 2.1, para comprobar que los enlaces se leen de verdad.
double _contraste(Color a, Color b) {
  double luminancia(Color c) {
    double canal(double v) {
      v = v / 255;
      return v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * canal(c.r * 255) +
        0.7152 * canal(c.g * 255) +
        0.0722 * canal(c.b * 255);
  }

  final l1 = luminancia(a);
  final l2 = luminancia(b);
  final claro = l1 > l2 ? l1 : l2;
  final oscuro = l1 > l2 ? l2 : l1;
  return (claro + 0.05) / (oscuro + 0.05);
}

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

  group('los enlaces se leen sobre el fondo de la app', () {
    // Estaban pintados con `primaryColor`, que en tema oscuro Flutter resuelve
    // a `colorScheme.surface`: quedaba #0B1A2E sobre #050B15, contraste 1.13:1.
    // Los enlaces estaban ahí y eran invisibles, en la pantalla donde se
    // aceptan las condiciones.
    testWidgets('con el tema real, el contraste supera el mínimo de AA', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: DocumentosLegalesEnlaces()),
        ),
      );

      final texto = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const Key('enlace-terminos')),
          matching: find.byType(Text),
        ),
      );

      final color = texto.style!.color!;
      expect(
        _contraste(color, AppTheme.legacyBlue1),
        greaterThanOrEqualTo(4.5),
        reason: 'el enlace debe leerse sobre el fondo del scaffold',
      );
    });

    testWidgets('un color explícito sigue mandando sobre el del tema', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: DocumentosLegalesEnlaces(color: Colors.white),
          ),
        ),
      );

      final texto = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const Key('enlace-privacidad')),
          matching: find.byType(Text),
        ),
      );

      expect(texto.style!.color, Colors.white);
    });
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
