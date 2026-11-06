import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:legacy_app/config/theme/app_theme.dart';
import 'package:legacy_app/data/config/config_service.dart';
import 'package:legacy_app/data/services/event_service.dart';
import 'package:legacy_app/domain/models/workshop_model.dart';
import 'package:legacy_app/domain/providers/auth_provider.dart';
import 'package:legacy_app/domain/providers/events_provider.dart';
import 'package:legacy_app/presentation/screens/eventos/agenda_screen.dart';
import 'package:provider/provider.dart';

/// «Mi agenda», rehecha el 2026-11-06 con el estilo del resto de la app.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final hoy = DateTime.now();
  Map<String, dynamic> ws(String id, String evento, String titulo, DateTime inicio) => {
    'id': id,
    'eventId': evento,
    'eventTitle': titulo,
    'name': 'Workshop $id',
    'room': 'Sala 1',
    'speaker': 'Ana Ruiz',
    'startDateTime': inicio.toUtc().toIso8601String(),
    'endDateTime': inicio.add(const Duration(hours: 1)).toUtc().toIso8601String(),
  };

  final pasado = hoy.subtract(const Duration(days: 10));
  final proximo = hoy.add(const Duration(days: 20));
  final lejano = hoy.add(const Duration(days: 40));
  final agenda = [
    ws('p1', 'ev-pasado', 'Evento terminado', pasado),
    ws('l1', 'ev-lejano', 'Summit lejano', lejano),
    ws('c2', 'ev-cerca', 'Masterclass cercana', proximo.add(const Duration(hours: 3))),
    ws('c1', 'ev-cerca', 'Masterclass cercana', proximo),
  ];

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('es', null);
    await ConfigService.initialize();
  });

  test('Agrupa por evento: próximos primero, pasados al final, por hora', () {
    final grupos = AgendaScreen.agrupar(
      agenda.map((j) => WorkshopModel.fromJson(j)).toList(),
    );
    expect(grupos.map((g) => g.first.eventId), ['ev-cerca', 'ev-lejano', 'ev-pasado']);
    expect(grupos.first.map((w) => w.id), ['c1', 'c2']);
  });

  Future<void> montar(WidgetTester tester, List<Map<String, dynamic>> datos) async {
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/agenda')) {
        return http.Response(jsonEncode(datos), 200);
      }
      return http.Response('[]', 200);
    });
    final provider = EventsProvider(eventService: EventService(client: client));
    await provider.loadAgenda('token');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => _AuthFake()),
          ChangeNotifierProvider<EventsProvider>.value(value: provider),
        ],
        child: const MaterialApp(home: AgendaScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Fondo oscuro, título del evento y calificar solo lo terminado', (
    tester,
  ) async {
    await montar(tester, agenda);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, AppTheme.legacyBlue1);
    expect(find.text('Mi agenda'), findsOneWidget);
    expect(find.text('Masterclass cercana'), findsOneWidget);

    // Solo el workshop del evento pasado se puede calificar.
    await tester.scrollUntilVisible(find.text('Calificar experiencia'), 200);
    expect(find.text('Calificar experiencia'), findsOneWidget);
    expect(find.text('Podrás calificarlo al terminar'), findsWidgets);
  });

  testWidgets('Sin workshops lo dice', (tester) async {
    await montar(tester, []);
    expect(find.text('No tienes workshops en tu agenda.'), findsOneWidget);
  });
}

class _AuthFake extends AuthProvider {
  @override
  String? get token => 'token-de-prueba';
}
