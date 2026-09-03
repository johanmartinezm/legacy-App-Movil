import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:legacy_app/data/services/paginas_service.dart';
import 'package:legacy_app/presentation/screens/paginas/pagina_informativa_screen.dart';

/// Monta la pantalla con un backend simulado.
Widget _pantalla(MockClient client) {
  return MaterialApp(
    home: PaginaInformativaScreen(
      slug: 'legacy-board',
      tituloProvisional: 'Legacy Board',
      servicio: PaginasService(client: client),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('pinta el titulo, el subtitulo y un parrafo por bloque',
      (tester) async {
    final client = MockClient((request) async => http.Response.bytes(
          utf8.encode(json.encode({
            'slug': 'legacy-board',
            'titulo': 'Legacy Board',
            'subtitulo': 'Gobierno corporativo',
            'imagen_url': '',
            'cuerpo': 'Primer párrafo.\n\nSegundo párrafo.',
            'publicada': true,
          })),
          200,
        ));

    await tester.pumpWidget(_pantalla(client));
    // Mientras carga se ve la rueda, no un hueco en blanco.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Gobierno corporativo'), findsOneWidget);
    expect(find.text('Primer párrafo.'), findsOneWidget);
    expect(find.text('Segundo párrafo.'), findsOneWidget);
    // El titulo sale dos veces: en la barra y como encabezado.
    expect(find.text('Legacy Board'), findsNWidgets(2));
  });

  testWidgets('una pagina despublicada explica que no esta disponible',
      (tester) async {
    final client = MockClient((request) async =>
        http.Response('la página no existe o no está publicada', 404));

    await tester.pumpWidget(_pantalla(client));
    await tester.pumpAndSettle();

    expect(find.textContaining('no está disponible'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    // La barra conserva el titulo: sin el, la pantalla parece rota.
    expect(find.text('Legacy Board'), findsOneWidget);
  });

  testWidgets('reintentar vuelve a pedir la pagina', (tester) async {
    var llamadas = 0;
    final client = MockClient((request) async {
      llamadas++;
      if (llamadas == 1) return http.Response('', 500);
      return http.Response.bytes(
        utf8.encode(json.encode({
          'slug': 'legacy-board',
          'titulo': 'Legacy Board',
          'cuerpo': 'Ya cargó.',
        })),
        200,
      );
    });

    await tester.pumpWidget(_pantalla(client));
    await tester.pumpAndSettle();
    expect(find.textContaining('conexión'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(llamadas, 2);
    expect(find.text('Ya cargó.'), findsOneWidget);
  });

  testWidgets('un cuerpo vacio no deja la pantalla muda', (tester) async {
    final client = MockClient((request) async => http.Response.bytes(
          utf8.encode(json.encode({
            'slug': 'legacy-board',
            'titulo': 'Legacy Board',
            'cuerpo': '',
          })),
          200,
        ));

    await tester.pumpWidget(_pantalla(client));
    await tester.pumpAndSettle();

    expect(find.textContaining('Pronto publicaremos'), findsOneWidget);
  });

  group('la flecha de atras', () {
    /// Un router con las dos rutas, para poder entrar por cada puerta: desde
    /// Inicio (apilando) o directo a la pagina (enlace profundo, sin pila).
    GoRouter router(String inicial, MockClient client) => GoRouter(
          initialLocation: inicial,
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => context.push('/legacy-board'),
                    child: const Text('ir al board'),
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/legacy-board',
              builder: (context, state) => PaginaInformativaScreen(
                slug: 'legacy-board',
                tituloProvisional: 'Legacy Board',
                servicio: PaginasService(client: client),
              ),
            ),
          ],
        );

    MockClient clienteConContenido() => MockClient((request) async =>
        http.Response.bytes(
          utf8.encode(json.encode({
            'slug': 'legacy-board',
            'titulo': 'Legacy Board',
            'cuerpo': 'Contenido.',
          })),
          200,
        ));

    testWidgets('entrando desde Inicio, vuelve a Inicio', (tester) async {
      final r = router('/home', clienteConContenido());
      await tester.pumpWidget(MaterialApp.router(routerConfig: r));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ir al board'));
      await tester.pumpAndSettle();
      expect(find.text('Contenido.'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();

      expect(find.text('ir al board'), findsOneWidget);
    });

    testWidgets('entrando por enlace profundo, la flecha lleva a Inicio',
        (tester) async {
      // Sin esto la flecha no hacia nada: `pop()` no tiene que quitar cuando la
      // pantalla es la primera de la pila.
      final r = router('/legacy-board', clienteConContenido());
      await tester.pumpWidget(MaterialApp.router(routerConfig: r));
      await tester.pumpAndSettle();
      expect(find.text('Contenido.'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();

      expect(find.text('ir al board'), findsOneWidget);
    });
  });
}
