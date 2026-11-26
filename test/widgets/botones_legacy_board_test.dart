import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:legacy_app/data/services/paginas_service.dart';
import 'package:legacy_app/domain/providers/auth_provider.dart';
import 'package:legacy_app/presentation/screens/contacto/contacto_screen.dart';
import 'package:legacy_app/presentation/screens/paginas/pagina_informativa_screen.dart';
import 'package:legacy_app/presentation/widgets/botones_legacy_board.dart';
import 'package:provider/provider.dart';

/// Legacy Board lleva al pie dos botones, solo para quien tiene el plus:
/// «Quiero ser parte» abre el Formulario A y «Quiero buscar» abre Contáctenos
/// con el asunto escrito, mientras no exista el Formulario B.
class _Auth extends AuthProvider {
  final bool plus;
  _Auth(this.plus);
  @override
  bool get esPlus => plus;
}

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
              acciones: BotonesLegacyBoard.desdePagina,
            ),
          ),
          GoRoute(
            path: '/legacy-board/formulario/:clave',
            builder: (context, state) => Scaffold(body: Text('formulario=${state.pathParameters['clave']}')),
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

  MockClient pagina([Map<String, dynamic> extra = const {}]) =>
      MockClient((request) async => http.Response.bytes(
            utf8.encode(json.encode({
              'slug': 'legacy-board',
              'titulo': 'Legacy Board',
              'cuerpo': 'Contenido.',
              ...extra,
            })),
            200,
          ));

  Future<void> montar(WidgetTester tester, MockClient client, {bool plus = true}) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ChangeNotifierProvider<AuthProvider>(
      create: (_) => _Auth(plus),
      child: MaterialApp.router(routerConfig: router(client)),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('los dos botones salen debajo del contenido', (tester) async {
    await montar(tester, pagina());
    expect(find.text('Contenido.'), findsOneWidget);
    expect(find.text('Quiero ser parte'), findsOneWidget);
    expect(find.text('Quiero buscar'), findsOneWidget);
  });

  testWidgets('los textos salen del panel', (tester) async {
    await montar(tester, pagina({
      'pregunta_acciones': '¿Qué busca?',
      'boton_principal': 'Postularme',
      'boton_secundario': 'Encontrar consejeros',
    }));
    expect(find.text('¿Qué busca?'), findsOneWidget);
    expect(find.text('Postularme'), findsOneWidget);
    expect(find.text('Encontrar consejeros'), findsOneWidget);
    expect(find.text('Quiero ser parte'), findsNothing);
  });

  testWidgets('un texto vacío del panel pinta el de siempre', (tester) async {
    await montar(tester, pagina({'boton_principal': 'Postularme', 'boton_secundario': '  '}));
    expect(find.text('¿Cómo quiere participar?'), findsOneWidget);
    expect(find.text('Postularme'), findsOneWidget);
    expect(find.text('Quiero buscar'), findsOneWidget);
  });

  testWidgets('sin el plus la página es solo informativa', (tester) async {
    await montar(tester, pagina(), plus: false);
    expect(find.text('Contenido.'), findsOneWidget);
    expect(find.text('¿Cómo quiere participar?'), findsNothing);
    expect(find.byKey(const Key('legacy-board-ser-parte')), findsNothing);
    expect(find.byKey(const Key('legacy-board-buscar')), findsNothing);
  });

  testWidgets('«Quiero ser parte» abre el Formulario A, con cualquier texto', (tester) async {
    await montar(tester, pagina({'boton_principal': 'Postularme'}));
    await tester.tap(find.byKey(const Key('legacy-board-ser-parte')));
    await tester.pumpAndSettle();
    expect(find.text('formulario=A'), findsOneWidget);
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
