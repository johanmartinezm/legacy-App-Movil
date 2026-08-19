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

/// 🔴 La propiedad que hay que preservar: lo que la tarjeta dice que cuesta un
/// evento sale del evento, no de como se llame su categoria.
///
/// Hasta el 2026-08-19 la tarjeta hacia `category == 'summit' ? ... : 'Gratis'`,
/// asi que una masterclass de 150.000 se anunciaba **Gratis** con insignia
/// **GRATIS**: bastaba abrir la lista para verlo. Salio al ejecutar F12.20 del
/// plan de pruebas.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final DateTime hoy = DateTime.now();
  String iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}T00:00:00Z';

  Map<String, dynamic> evento({
    required String id,
    required String titulo,
    required String categoria,
    required num precio,
    required bool gratis,
  }) => {
    'id': id,
    'title': titulo,
    'category': categoria,
    'date': iso(hoy.add(const Duration(days: 30))),
    'location': 'Bogotá',
    'price': precio,
    'isFree': gratis,
    'actionStatus': '',
    'buttonText': '',
    'description': '',
  };

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await ConfigService.initialize();
  });

  Future<void> montar(WidgetTester tester, List<Map<String, dynamic>> eventos) async {
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/events')) {
        return http.Response(jsonEncode(eventos), 200);
      }
      return http.Response('[]', 200);
    });
    final eventsProvider = EventsProvider(eventService: EventService(client: client));
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, _) => const EventosScreen())],
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
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();
  }

  testWidgets('una masterclass de pago muestra su precio, no «Gratis»', (tester) async {
    await montar(tester, [
      evento(
        id: '1',
        titulo: 'Masterclass de pago',
        categoria: 'masterclass',
        precio: 150000,
        gratis: false,
      ),
    ]);

    expect(find.text('Masterclass de pago'), findsOneWidget);
    expect(find.text('Gratis'), findsNothing);
    expect(find.text('GRATIS'), findsNothing);
    expect(find.textContaining('150.000'), findsOneWidget);
    expect(find.text('PREVENTA'), findsOneWidget);
  });

  testWidgets('un evento gratuito sigue diciendo que es gratis', (tester) async {
    await montar(tester, [
      evento(
        id: '2',
        titulo: 'Conversatorio abierto',
        categoria: 'masterclass',
        precio: 0,
        gratis: true,
      ),
    ]);

    expect(find.text('Gratis'), findsOneWidget);
    expect(find.text('GRATIS'), findsOneWidget);
    expect(find.text('PREVENTA'), findsNothing);
  });

  // El summit era el unico evento de pago cuando se escribio la tarjeta. Debe
  // seguir viendose igual, pero ahora porque cuesta, no porque se llame asi.
  testWidgets('el summit de pago se comporta como cualquier otro evento de pago', (tester) async {
    await montar(tester, [
      evento(
        id: '3',
        titulo: 'LEGACY SUMMIT 2026',
        categoria: 'summit',
        precio: 250000,
        gratis: false,
      ),
    ]);

    expect(find.textContaining('250.000'), findsOneWidget);
    expect(find.text('PREVENTA'), findsOneWidget);
    expect(find.text('Gratis'), findsNothing);
  });

  // Ya no hay ninguna fecha escrita a mano: «Preventa hasta 30 jul» seguia
  // saliendo en agosto.
  testWidgets('no queda ninguna fecha de preventa fija en la tarjeta', (tester) async {
    await montar(tester, [
      evento(
        id: '4',
        titulo: 'LEGACY SUMMIT 2026',
        categoria: 'summit',
        precio: 250000,
        gratis: false,
      ),
    ]);

    expect(find.textContaining('30 jul'), findsNothing);
  });
}
