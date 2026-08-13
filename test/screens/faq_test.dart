import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:legacy_app/domain/models/faq_data.dart';
import 'package:legacy_app/presentation/screens/faq/faq_screen.dart';

Widget _app() {
  final router = GoRouter(
    initialLocation: '/faq',
    routes: [
      GoRoute(path: '/faq', builder: (_, __) => const FaqScreen()),
      GoRoute(path: '/contacto', builder: (_, __) => const Scaffold(body: Text('pantalla de contacto'))),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  group('contenido', () {
    test('tiene las cuatro secciones que pide el documento de alcance', () {
      expect(seccionesFaq, hasLength(4));
    });

    test('ninguna sección está vacía y ningún texto está en blanco', () {
      for (final seccion in seccionesFaq) {
        expect(seccion.titulo.trim(), isNotEmpty);
        expect(seccion.preguntas, isNotEmpty, reason: 'sección "${seccion.titulo}" sin preguntas');
        for (final p in seccion.preguntas) {
          expect(p.pregunta.trim(), isNotEmpty);
          expect(p.respuesta.trim(), isNotEmpty, reason: 'respuesta vacía en "${p.pregunta}"');
        }
      }
    });

    test('no hay preguntas repetidas', () {
      final todas = seccionesFaq.expand((s) => s.preguntas).map((p) => p.pregunta).toList();
      expect(todas.toSet(), hasLength(todas.length));
    });
  });

  group('pantalla', () {
    testWidgets('muestra las cuatro secciones al abrirse', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      // El ListView solo construye lo que cabe en pantalla, así que las últimas
      // secciones hay que traerlas desplazando.
      for (final seccion in seccionesFaq) {
        await tester.scrollUntilVisible(
          find.text(seccion.titulo.toUpperCase()),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(seccion.titulo.toUpperCase()), findsOneWidget);
      }
    });

    testWidgets('la respuesta aparece al tocar la pregunta', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      final primera = seccionesFaq.first.preguntas.first;
      expect(find.text(primera.respuesta), findsNothing);

      await tester.tap(find.text(primera.pregunta));
      await tester.pumpAndSettle();

      expect(find.text(primera.respuesta), findsOneWidget);
    });

    testWidgets('buscar deja solo lo que coincide, sin escribir tildes', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      // "contrasena" sin tilde y sin ñ tiene que encontrar "contraseña".
      await tester.enterText(find.byType(TextField), 'contrasena');
      await tester.pumpAndSettle();

      expect(find.text('Olvidé mi contraseña'), findsOneWidget);
      expect(find.text('¿Los foros son anónimos?'), findsNothing);
    });

    testWidgets('al buscar, las coincidencias salen ya desplegadas', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'contrasena');
      await tester.pumpAndSettle();

      // Sin esto habría que tocar cada resultado para ver si es el bueno.
      expect(find.textContaining('Olvidaste tu contraseña'), findsOneWidget);
    });

    testWidgets('sin coincidencias ofrece escribir al equipo', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pumpAndSettle();

      expect(find.textContaining('Ninguna pregunta coincide'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Contáctenos'));
      await tester.pumpAndSettle();

      expect(find.text('pantalla de contacto'), findsOneWidget);
    });
  });
}
