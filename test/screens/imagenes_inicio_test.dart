import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:legacy_app/data/config/config_service.dart';
import 'package:legacy_app/data/services/chat_service.dart';
import 'package:legacy_app/data/services/secciones_inicio_service.dart';
import 'package:legacy_app/domain/providers/auth_provider.dart';
import 'package:legacy_app/domain/providers/chat_provider.dart';
import 'package:legacy_app/domain/providers/notification_provider.dart';
import 'package:legacy_app/presentation/screens/home/home_content_screen.dart';
import 'package:provider/provider.dart';

/// Las tarjetas del Inicio toman su imagen, su título y su texto de
/// GET /api/inicio/secciones, que edita el panel. Lo que venga vacío —o todo,
/// sin backend— se pinta como siempre: el Inicio no puede quedarse en blanco
/// por un fallo de red.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await ConfigService.initialize();
  });

  SeccionesInicioService servicio(http.Response Function() respuesta) =>
      SeccionesInicioService(client: MockClient((_) async => respuesta()));

  http.Response secciones(
    Map<String, String> imagenes, {
    Map<String, String> titulos = const {},
    Map<String, String> textos = const {},
  }) =>
      http.Response(
        jsonEncode([
          for (final slug in const [
            'nuevo-cada-semana',
            'legacy-board',
            'eventos',
            'beneficios',
            'miembros',
            'legacy-test',
          ])
            {
              'slug': slug,
              'nombre': slug,
              'orden': 0,
              'imagen_url': imagenes[slug] ?? '',
              'titulo': titulos[slug] ?? '',
              'texto': textos[slug] ?? '',
            },
        ]),
        200,
      );

  group('SeccionesInicioService', () {
    test('devuelve solo las secciones con algo cambiado, recortado', () async {
      final r = await servicio(
        () => secciones(
          {'eventos': ' https://x/e.jpg '},
          titulos: {'miembros': ' Comunidad '},
        ),
      ).secciones();
      expect(r.keys, unorderedEquals(['eventos', 'miembros']));
      expect(r['eventos']!.imagenUrl, 'https://x/e.jpg');
      expect(r['eventos']!.titulo, isNull);
      expect(r['miembros']!.titulo, 'Comunidad');
      expect(r['miembros']!.imagenUrl, isNull);
    });

    test('un backend sin titulo ni texto sigue sirviendo la imagen', () async {
      final r = await servicio(
        () => http.Response(
          jsonEncode([
            {'slug': 'eventos', 'imagen_url': 'https://x/e.jpg'},
          ]),
          200,
        ),
      ).secciones();
      expect(r['eventos']!.imagenUrl, 'https://x/e.jpg');
      expect(r['eventos']!.titulo, isNull);
      expect(r['eventos']!.texto, isNull);
    });

    test('un error del backend no rompe nada: mapa vacío', () async {
      expect(await servicio(() => http.Response('boom', 500)).secciones(), isEmpty);
      expect(await servicio(() => http.Response('no es json', 200)).secciones(), isEmpty);
      expect(
        await SeccionesInicioService(
          client: MockClient((_) async => throw Exception('sin red')),
        ).secciones(),
        isEmpty,
      );
    });
  });

  Future<void> montar(WidgetTester tester, SeccionesInicioService s) async {
    tester.view.physicalSize = const Size(1080, 4000);
    // Ancha a propósito: la fuente de pruebas es más ancha que la real y
    // a 392 px de ancho desborda textos que en el teléfono caben.
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
          ChangeNotifierProvider<NotificationProvider>(
            create: (_) => NotificationProvider(),
          ),
          ChangeNotifierProvider<ChatProvider>(
            create: (_) => ChatProvider(ChatService('')),
          ),
        ],
        child: MaterialApp(home: HomeContentScreen(seccionesService: s)),
      ),
    );
    // Deja responder al servicio sin esperar a que carguen las fotos.
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Las secciones con imagen la muestran; las demás, su icono', (
    tester,
  ) async {
    await montar(
      tester,
      servicio(() => secciones({
            'eventos': 'https://x/eventos.jpg',
            'beneficios': 'https://x/beneficios.jpg',
            'legacy-test': 'https://x/test.jpg',
          })),
    );

    expect(find.byKey(const Key('tarjeta-eventos-con-imagen')), findsOneWidget);
    expect(find.byKey(const Key('tarjeta-legacy-test-con-imagen')), findsOneWidget);
    // Beneficios ya solo es la fila de la sección Legacy+ (la tarjeta de la
    // cuadrícula se retiró el 2026-10-13).
    expect(find.byKey(const Key('tarjeta-beneficios-con-imagen')), findsOneWidget);

    expect(find.byKey(const Key('tarjeta-legacy-board')), findsOneWidget);
    expect(find.byKey(const Key('tarjeta-nuevo-cada-semana')), findsOneWidget);
    expect(find.byIcon(Icons.dashboard), findsOneWidget);
    // Con imagen, el icono de la tarjeta se retira.
    expect(find.byIcon(Icons.calendar_month), findsNothing);
    // El texto sigue en su sitio.
    expect(find.text('Eventos'), findsOneWidget);
  });

  testWidgets('El título y el texto del panel sustituyen a los de la app', (
    tester,
  ) async {
    await montar(
      tester,
      servicio(() => secciones(
            const {},
            titulos: {'eventos': 'Agenda 2026', 'legacy-test': 'Haga el test'},
            textos: {'eventos': 'Todo el calendario', 'miembros': 'Red de socios'},
          )),
    );

    expect(find.text('Agenda 2026'), findsOneWidget);
    expect(find.text('Todo el calendario'), findsOneWidget);
    expect(find.text('Haga el test'), findsOneWidget);
    expect(find.text('Red de socios'), findsOneWidget);
    // Lo que el panel no cambió sigue con el de siempre.
    expect(find.text('Miembros'), findsOneWidget);
    expect(find.text('Legacy Board'), findsOneWidget);
    // Lo sustituido ya no aparece.
    expect(find.text('Masterclass virtual en vivo y Legacy Summit presencial'), findsNothing);
    // Sin imagen, conserva el icono.
    expect(find.byKey(const Key('tarjeta-eventos')), findsOneWidget);
  });

  testWidgets('Chats de sinergia está en la sección Legacy+, con candado si no es cliente', (tester) async {
    await montar(tester, servicio(() => http.Response('boom', 500)));

    expect(find.text('Chats de sinergia'), findsOneWidget);
    expect(find.byKey(const Key('tarjeta-chats-sinergia')), findsOneWidget);
    await tester.tap(find.text('Chats de sinergia'));
    await tester.pump();
    expect(find.text('Esta sección es exclusiva para clientes Legacy.'), findsOneWidget);
  });

  testWidgets('Sin backend, el Inicio se ve como siempre', (tester) async {
    await montar(tester, servicio(() => http.Response('boom', 500)));

    expect(find.byKey(const Key('tarjeta-eventos')), findsOneWidget);
    expect(find.byKey(const Key('tarjeta-eventos-con-imagen')), findsNothing);
    expect(find.byIcon(Icons.calendar_month), findsOneWidget);
  });
}
