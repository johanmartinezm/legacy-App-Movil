import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:legacy_app/data/config/config_service.dart';
import 'package:legacy_app/data/services/event_service.dart';
import 'package:legacy_app/domain/models/workshop_model.dart';
import 'package:legacy_app/domain/providers/auth_provider.dart';
import 'package:legacy_app/domain/providers/events_provider.dart';
import 'package:legacy_app/presentation/widgets/eventos/calificar_workshop.dart';
import 'package:provider/provider.dart';

class _AuthFake extends AuthProvider {
  @override
  String? get token => 'token-de-prueba';
}

/// Hallazgo 3 del recorrido del 2026-11-09: «Calificar experiencia» salía en un
/// workshop ya calificado, y solo al enviar se leía «ya calificaste».
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await ConfigService.initialize();
  });

  final workshop = WorkshopModel.fromJson({
    'id': 'w-1',
    'eventId': 'ev-1',
    'name': 'Gobierno de la empresa familiar',
    'startDateTime': '2026-10-27T15:00:00-05:00',
    'endDateTime': '2026-10-27T16:30:00-05:00',
  });

  late List<Uri> pedidas;

  Future<void> montar(
    WidgetTester tester,
    List<Map<String, dynamic>> misCalificaciones,
  ) async {
    pedidas = [];
    final client = MockClient((request) async {
      pedidas.add(request.url);
      if (request.url.path.endsWith('/workshop-ratings/me')) {
        return http.Response(jsonEncode(misCalificaciones), 200);
      }
      return http.Response('[]', 200);
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => _AuthFake()),
          ChangeNotifierProvider<EventsProvider>(
            create: (_) =>
                EventsProvider(eventService: EventService(client: client)),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                // Dos tarjetas del mismo evento: se pide una sola vez.
                CalificarWorkshop(workshop: workshop),
                CalificarWorkshop(workshop: workshop),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
  }

  testWidgets('ya calificado: dice «Tu calificación» y no ofrece calificar', (
    tester,
  ) async {
    await montar(tester, [
      {'workshopId': 'w-1', 'rating': 3},
    ]);

    expect(find.byKey(const Key('workshop-ya-calificado')), findsNWidgets(2));
    expect(find.byKey(const Key('workshop-calificar')), findsNothing);
    expect(find.bySemanticsLabel('3 de 5 estrellas'), findsNWidgets(2));
    expect(
      pedidas.where((u) => u.path == '/api/events/ev-1/workshop-ratings/me'),
      hasLength(1),
    );
  });

  testWidgets('sin calificar: ofrece «Calificar experiencia»', (tester) async {
    await montar(tester, []);

    expect(find.byKey(const Key('workshop-calificar')), findsNWidgets(2));
    expect(find.byKey(const Key('workshop-ya-calificado')), findsNothing);
  });

  testWidgets('si la consulta falla, se ofrece calificar como antes', (
    tester,
  ) async {
    final client = MockClient((_) async => http.Response('boom', 500));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => _AuthFake()),
          ChangeNotifierProvider<EventsProvider>(
            create: (_) =>
                EventsProvider(eventService: EventService(client: client)),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(body: CalificarWorkshop(workshop: workshop)),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('workshop-calificar')), findsOneWidget);
  });
}
