import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:legacy_app/data/config/config_service.dart';
import 'package:legacy_app/data/services/event_service.dart';
import 'package:legacy_app/domain/models/event_model.dart';
import 'package:legacy_app/domain/models/workshop_model.dart';
import 'package:legacy_app/domain/providers/auth_provider.dart';
import 'package:legacy_app/domain/providers/events_provider.dart';
import 'package:legacy_app/presentation/screens/eventos/cronograma_screen.dart';
import 'package:legacy_app/presentation/screens/eventos/event_purchase_detail_screen.dart';
import 'package:provider/provider.dart';

class _AuthFake extends AuthProvider {
  @override
  String? get token => 'token-de-prueba';
}

/// El cronograma existía desde el commit inicial, pero ninguna pantalla lo
/// abría: los talleres no se veían en la app, «Mi agenda» no tenía de dónde
/// llenarse y no había forma de calificar un taller. Desde el 2026-10-28 se
/// llega desde el detalle del evento.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await ConfigService.initialize();
    await initializeDateFormatting('es');
  });

  EventModel evento({List<Map<String, dynamic>> talleres = const []}) =>
      EventModel.fromJson({
        'id': 'event-1',
        'title': 'Legacy Summit',
        'category': 'summit',
        'date': '2026-11-18T00:00:00Z',
        'price': 0,
        'isFree': true,
        'actionStatus': 'register',
        'buttonText': 'Reservar cupo gratis',
        'description': 'Descripción',
        'imageUrl': '',
        'workshops': talleres,
      });

  final taller = {
    'id': 'ws-1',
    'name': 'Protocolo de sucesión',
    'description': 'Preparar el relevo generacional.',
    'room': 'Sala 2',
    'speaker': 'Andrés Ruiz',
    'startDateTime': '2026-11-19T11:00:00-05:00',
    'endDateTime': '2026-11-19T12:30:00-05:00',
  };

  Future<void> montar(WidgetTester tester, EventModel event) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final client = MockClient((_) async => http.Response(jsonEncode([]), 200));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => _AuthFake()),
          ChangeNotifierProvider<EventsProvider>(
            create: (_) =>
                EventsProvider(eventService: EventService(client: client)),
          ),
        ],
        child: MaterialApp(home: EventPurchaseDetailScreen(event: event)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Sin talleres no hay botón de cronograma', (tester) async {
    await montar(tester, evento());
    expect(find.textContaining('VER CRONOGRAMA'), findsNothing);
  });

  testWidgets('Con talleres, el botón abre el cronograma con su taller', (
    tester,
  ) async {
    await montar(tester, evento(talleres: [taller]));

    final boton = find.text('VER CRONOGRAMA · 1 TALLER');
    expect(boton, findsOneWidget);

    await tester.tap(boton);
    await tester.pumpAndSettle();

    expect(find.byType(CronogramaScreen), findsOneWidget);
    expect(find.text('Protocolo de sucesión'), findsOneWidget);
    expect(find.text('Sala 2'), findsOneWidget);
    expect(find.text('Andrés Ruiz'), findsOneWidget);
    expect(find.text('Preparar el relevo generacional.'), findsOneWidget);
  });

  // Fechas relativas a hoy: con fechas fijas, el taller «futuro» dejaría de
  // serlo con el paso de los días y la prueba fallaría sola.
  Map<String, dynamic> tallerQueTermina(Duration desdeAhora) {
    final fin = DateTime.now().add(desdeAhora);
    return Map<String, dynamic>.from(taller)
      ..['startDateTime'] = fin
          .subtract(const Duration(hours: 1))
          .toUtc()
          .toIso8601String()
      ..['endDateTime'] = fin.toUtc().toIso8601String();
  }

  Future<void> abrirCronograma(WidgetTester tester, EventModel event) async {
    await montar(tester, event);
    await tester.tap(find.textContaining('VER CRONOGRAMA'));
    await tester.pumpAndSettle();
  }

  testWidgets('Taller que no ha terminado: no se ofrece calificar', (
    tester,
  ) async {
    await abrirCronograma(
      tester,
      evento(talleres: [tallerQueTermina(const Duration(days: 30))]),
    );

    expect(find.text('Calificar experiencia'), findsNothing);
    expect(find.text('Podrás calificarlo al terminar'), findsOneWidget);
  });

  testWidgets('Taller terminado: se ofrece calificar', (tester) async {
    await abrirCronograma(
      tester,
      evento(talleres: [tallerQueTermina(const Duration(days: -30))]),
    );

    expect(find.text('Calificar experiencia'), findsOneWidget);
    expect(find.text('Podrás calificarlo al terminar'), findsNothing);
  });

  test('Calificar dos veces muestra el motivo del servidor', () async {
    final client = MockClient(
      (_) async => http.Response('ya calificaste este taller', 409),
    );
    final provider = EventsProvider(eventService: EventService(client: client));

    await expectLater(
      provider.submitWorkshopRating(
        workshopId: 'ws-1',
        rating: 4,
        comment: '',
        token: 't',
      ),
      throwsA(isA<MotivoDelServidor>()),
    );
    expect(provider.errorMessage, 'ya calificaste este taller');
  });

  test('La hora del taller se lee en la hora local, no en UTC', () {
    final w = WorkshopModel.fromJson(taller);
    final esperado = DateTime.parse('2026-11-19T11:00:00-05:00').toLocal();

    expect(w.startDateTime.isUtc, isFalse);
    expect(w.startDateTime.hour, esperado.hour);
    expect(w.startDateTime, esperado);
  });
}
