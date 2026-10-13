import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:legacy_app/data/services/paginas_service.dart';
import 'package:legacy_app/presentation/screens/contacto/contacto_screen.dart';
import 'package:legacy_app/presentation/screens/paginas/pagina_informativa_screen.dart';
import 'package:legacy_app/presentation/widgets/botones_legacy_board.dart';

/// Legacy Board lleva al pie dos botones que abren Contáctenos con el asunto
/// ya escrito, mientras no existan los formularios A y B.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  GoRouter router(MockClient client) => GoRouter(
        initialLocation: '/legacy-board',
        routes: [
          GoRoute(
            path: '/legacy-board',
            builder: (context, state) => PaginaInformativaScreen(
              slug: 'legacy-board',
              tituloProvisional: 'Legacy Board',
              servicio: PaginasService(client: client),
              acciones: const BotonesLegacyBoard(),
            ),
          ),
          // Contáctenos de mentira: solo enseña el asunto que le llega, que
          // es lo que main.dart pasa a ContactoScreen.
          GoRoute(
            path: '/contacto',
            builder: (context, state) =>
                Scaffold(body: Text('asunto=${state.uri.queryParameters['asunto']}')),
          ),
        ],
      );

  MockClient pagina() => MockClient((request) async => http.Response.bytes(
        utf8.encode(json.encode({
          'slug': 'legacy-board',
          'titulo': 'Legacy Board',
          'cuerpo': 'Contenido.',
        })),
        200,
      ));

  Future<void> montar(WidgetTester tester, MockClient client) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router(client)));
    await tester.pumpAndSettle();
  }

  testWidgets('los dos botones salen debajo del contenido', (tester) async {
    await montar(tester, pagina());
    expect(find.text('Contenido.'), findsOneWidget);
    expect(find.text('Quiero ser parte'), findsOneWidget);
    expect(find.text('Quiero buscar'), findsOneWidget);
  });

  testWidgets('«Quiero ser parte» abre Contáctenos con su asunto', (tester) async {
    await montar(tester, pagina());
    await tester.tap(find.byKey(const Key('legacy-board-ser-parte')));
    await tester.pumpAndSettle();
    expect(find.text('asunto=${BotonesLegacyBoard.asuntoSerParte}'), findsOneWidget);
  });

  testWidgets('«Quiero buscar» abre Contáctenos con su asunto', (tester) async {
    await montar(tester, pagina());
    await tester.tap(find.byKey(const Key('legacy-board-buscar')));
    await tester.pumpAndSettle();
    expect(find.text('asunto=${BotonesLegacyBoard.asuntoBuscar}'), findsOneWidget);
  });

  testWidgets('Contáctenos abre con el asunto ya escrito', (tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(
      home: ContactoScreen(asuntoInicial: BotonesLegacyBoard.asuntoBuscar),
    ));
    await tester.pump();
    expect(
      find.widgetWithText(TextFormField, BotonesLegacyBoard.asuntoBuscar),
      findsOneWidget,
    );
  });

  testWidgets('si la página no carga, no hay botones', (tester) async {
    await montar(tester, MockClient((_) async => http.Response('boom', 500)));
    expect(find.text('Quiero ser parte'), findsNothing);
  });
}
