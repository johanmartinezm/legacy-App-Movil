import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:legacy_app/data/config/config_service.dart';
import 'package:legacy_app/data/services/event_service.dart';
import 'package:legacy_app/domain/providers/auth_provider.dart';
import 'package:legacy_app/domain/providers/events_provider.dart';
import 'package:legacy_app/presentation/screens/eventos/eventos_screen.dart';
import 'package:provider/provider.dart';

/// Monta la pantalla de eventos contra una respuesta calcada de la que
/// devuelve producción hoy: un evento por venir y dos ya terminados.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final DateTime hoy = DateTime.now();
  String iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}T00:00:00Z';

  final String respuestaEventos = jsonEncode([
    {
      'id': '1',
      'title': 'LEGACY SUMMIT 2026',
      'category': 'summit',
      'date': iso(hoy.add(const Duration(days: 70))),
      'end_date': iso(hoy.add(const Duration(days: 72))),
      'location': 'Bogotá',
      'price': 250000,
      'isFree': false,
      'actionStatus': '',
      'buttonText': 'Comprar',
      'description': '',
    },
    {
      'id': '2',
      'title': 'Coffee & Networking: CDMX 2026',
      'category': 'coffee',
      'date': iso(hoy.subtract(const Duration(days: 115))),
      'location': 'Ciudad de México',
      'price': 0,
      'isFree': true,
      'actionStatus': 'registered',
      'buttonText': 'Registrado',
      'description': '',
    },
    {
      'id': '3',
      'title': 'Planificación Patrimonial en la Era Digital',
      'category': 'masterclass',
      'date': iso(hoy.subtract(const Duration(days: 138))),
      'speaker': 'Ana Gómez',
      'price': 0,
      'isFree': true,
      'actionStatus': '',
      'buttonText': 'Ver',
      'description': '',
    },
  ]);

  setUpAll(() async {
    // Sin fuentes de red en test; usa las de sistema.
    GoogleFonts.config.allowRuntimeFetching = false;
    await ConfigService.initialize();
  });

  Future<void> montarPantalla(WidgetTester tester) async {
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/events')) {
        return http.Response(respuestaEventos, 200);
      }
      return http.Response('[]', 200);
    });

    final eventsProvider = EventsProvider(
      eventService: EventService(client: client),
    );

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const EventosScreen()),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
          ChangeNotifierProvider<EventsProvider>.value(value: eventsProvider),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    // Un pump por el postFrameCallback que dispara loadEvents y otro por la
    // respuesta del servicio.
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();
  }

  testWidgets('Próximos muestra solo los eventos por venir', (tester) async {
    await montarPantalla(tester);

    expect(find.text('LEGACY SUMMIT 2026'), findsOneWidget);
    expect(find.text('Coffee & Networking: CDMX 2026'), findsNothing);
    expect(
      find.text('Planificación Patrimonial en la Era Digital'),
      findsNothing,
    );
  });

  testWidgets('Pasados muestra el histórico con la insignia FINALIZADO', (
    tester,
  ) async {
    await montarPantalla(tester);
    await tester.tap(find.text('Pasados'));
    await tester.pumpAndSettle();

    expect(find.text('Coffee & Networking: CDMX 2026'), findsOneWidget);
    expect(
      find.text('Planificación Patrimonial en la Era Digital'),
      findsOneWidget,
    );
    expect(find.text('LEGACY SUMMIT 2026'), findsNothing);
    expect(find.text('FINALIZADO'), findsNWidgets(2));
  });

  testWidgets('El histórico sale del más reciente al más antiguo', (
    tester,
  ) async {
    await montarPantalla(tester);
    await tester.tap(find.text('Pasados'));
    await tester.pumpAndSettle();

    final coffee = tester
        .getTopLeft(find.text('Coffee & Networking: CDMX 2026'))
        .dy;
    final masterclass = tester
        .getTopLeft(find.text('Planificación Patrimonial en la Era Digital'))
        .dy;
    expect(coffee, lessThan(masterclass));
  });

  testWidgets('La búsqueda filtra por título', (tester) async {
    await montarPantalla(tester);
    await tester.tap(find.text('Pasados'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'networking');
    await tester.pumpAndSettle();

    expect(find.text('Coffee & Networking: CDMX 2026'), findsOneWidget);
    expect(
      find.text('Planificación Patrimonial en la Era Digital'),
      findsNothing,
    );
  });

  testWidgets('La búsqueda encuentra por conferencista', (tester) async {
    await montarPantalla(tester);
    await tester.tap(find.text('Pasados'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'ana');
    await tester.pumpAndSettle();

    expect(
      find.text('Planificación Patrimonial en la Era Digital'),
      findsOneWidget,
    );
    expect(find.text('Coffee & Networking: CDMX 2026'), findsNothing);
  });

  testWidgets('Sin coincidencias aparece el aviso y Quitar filtros restaura', (
    tester,
  ) async {
    await montarPantalla(tester);
    await tester.tap(find.text('Pasados'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pumpAndSettle();
    expect(find.text('Ningún evento coincide con la búsqueda.'), findsOneWidget);

    await tester.tap(find.text('Quitar filtros'));
    await tester.pumpAndSettle();
    expect(find.text('Coffee & Networking: CDMX 2026'), findsOneWidget);
  });

  testWidgets('El filtro de categoría acota el listado', (tester) async {
    await montarPantalla(tester);
    await tester.tap(find.text('Pasados'));
    await tester.pumpAndSettle();

    // Dos categorías en el histórico: la fila de filtros debe estar visible.
    expect(find.text('Todas'), findsOneWidget);
    await tester.tap(find.text('Masterclass'));
    await tester.pumpAndSettle();

    expect(
      find.text('Planificación Patrimonial en la Era Digital'),
      findsOneWidget,
    );
    expect(find.text('Coffee & Networking: CDMX 2026'), findsNothing);
  });

  testWidgets('Con una sola categoría no se muestra la fila de filtros', (
    tester,
  ) async {
    await montarPantalla(tester);

    // Próximos tiene un único evento, de categoría summit.
    expect(find.text('LEGACY SUMMIT 2026'), findsOneWidget);
    expect(find.text('Todas'), findsNothing);
  });

  testWidgets('Al cambiar de pestaña la categoría vuelve a Todas', (
    tester,
  ) async {
    await montarPantalla(tester);
    await tester.tap(find.text('Pasados'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coffee'));
    await tester.pumpAndSettle();
    expect(find.text('Planificación Patrimonial en la Era Digital'), findsNothing);

    await tester.tap(find.text('Mis registros'));
    await tester.pumpAndSettle();
    // La categoría 'coffee' no debe seguir aplicada y ocultar resultados.
    expect(find.text('Coffee & Networking: CDMX 2026'), findsOneWidget);
  });
}
