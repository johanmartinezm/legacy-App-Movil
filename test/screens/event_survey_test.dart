import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:legacy_app/data/config/config_service.dart';
import 'package:legacy_app/data/services/event_service.dart';
import 'package:legacy_app/domain/providers/auth_provider.dart';
import 'package:legacy_app/domain/providers/events_provider.dart';
import 'package:legacy_app/presentation/widgets/eventos/event_survey_dialog.dart';
import 'package:provider/provider.dart';

/// Sesión iniciada. `AuthProvider` no expone un setter del token —y añadir uno
/// solo para las pruebas ensuciaría el código de producción—, así que se
/// sustituye el getter.
class _AuthConToken extends AuthProvider {
  @override
  String? get token => 'token-de-prueba';
}

/// Ejercita la encuesta general contra respuestas calcadas de las que devuelve
/// el backend: 204 sin responder, 201 al enviar, 403 sin registro y 409 al
/// repetir.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const encuestaGuardada = {
    'id': 'survey-1',
    'eventId': 'event-1',
    'userId': 'user-1',
    'overallRating': 5,
    'organizationRating': 4,
    'contentRating': 5,
    'speakersRating': null,
    'wouldRecommend': true,
    'comment': 'Todo excelente',
    'createdAt': '2026-08-05T18:25:04.000000Z',
  };

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await ConfigService.initialize();
  });

  /// Monta el diálogo con un cliente que responde según lo pactado por prueba.
  /// Devuelve el provider y la lista de cuerpos enviados, para poder afirmar
  /// sobre lo que viajó de verdad por la red.
  Future<(EventsProvider, List<String>)> montarDialogo(
    WidgetTester tester, {
    required http.Response Function(http.Request) responder,
  }) async {
    // El formulario completo no cabe en los 800x600 por defecto y el botón de
    // enviar queda fuera del viewport, donde el tap no llega.
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final enviados = <String>[];
    final client = MockClient((request) async {
      if (request.method == 'POST') enviados.add(request.body);
      return responder(request);
    });

    final provider = EventsProvider(
      eventService: EventService(client: client),
    );
    final auth = _AuthConToken();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<EventsProvider>.value(value: provider),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => const EventSurveyDialog(
                eventId: 'event-1',
                eventTitle: 'LEGACY SUMMIT 2026',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (provider, enviados);
  }

  testWidgets('El formulario aparece con el título del evento', (tester) async {
    await montarDialogo(
      tester,
      responder: (_) => http.Response('', 204),
    );

    expect(find.text('Cuéntanos tu experiencia'), findsOneWidget);
    expect(find.text('LEGACY SUMMIT 2026'), findsOneWidget);
    expect(find.byKey(const Key('survey-submit')), findsOneWidget);
  });

  testWidgets('Sin calificación general avisa y no llama al backend', (
    tester,
  ) async {
    final (_, enviados) = await montarDialogo(
      tester,
      responder: (_) => http.Response('', 204),
    );

    await tester.tap(find.byKey(const Key('survey-submit')));
    await tester.pump();

    expect(find.text('Danos al menos tu calificación general'), findsOneWidget);
    expect(enviados, isEmpty);
  });

  testWidgets('Envía solo las preguntas respondidas', (tester) async {
    // Las opcionales sin tocar no deben viajar como 0: el CHECK de la tabla
    // exige entre 1 y 5, y el backend distingue null de una nota baja.
    final (provider, enviados) = await montarDialogo(
      tester,
      responder: (r) => r.method == 'POST'
          ? http.Response(jsonEncode(encuestaGuardada), 201)
          : http.Response('', 204),
    );

    final estrellas = find.descendant(
      of: find.byKey(const Key('survey-overall')),
      matching: find.byIcon(Icons.star_rounded),
    );
    await tester.tap(estrellas.at(4));
    await tester.pump();

    await tester.tap(find.byKey(const Key('survey-submit')));
    await tester.pumpAndSettle();

    expect(enviados, hasLength(1));
    final cuerpo = jsonDecode(enviados.single) as Map<String, dynamic>;
    expect(cuerpo['overallRating'], 5);
    expect(cuerpo.containsKey('organizationRating'), isFalse);
    expect(cuerpo.containsKey('contentRating'), isFalse);
    expect(cuerpo.containsKey('comment'), isFalse);
    expect(provider.mySurveyFor('event-1'), isNotNull);
  });

  testWidgets('Un 403 explica que hay que estar registrado', (tester) async {
    final (provider, _) = await montarDialogo(
      tester,
      responder: (r) => r.method == 'POST'
          ? http.Response('user is not registered for this event', 403)
          : http.Response('', 204),
    );

    final estrellas = find.descendant(
      of: find.byKey(const Key('survey-overall')),
      matching: find.byIcon(Icons.star_rounded),
    );
    await tester.tap(estrellas.at(2));
    await tester.pump();

    await tester.tap(find.byKey(const Key('survey-submit')));
    await tester.pumpAndSettle();

    expect(provider.errorMessage, contains('registraron'));
    expect(provider.mySurveyFor('event-1'), isNull);
  });

  testWidgets('Un 409 se resuelve mostrando la respuesta ya enviada', (
    tester,
  ) async {
    // El objetivo del usuario está cumplido: lo que procede es enseñarle lo que
    // respondió, no un error.
    final (provider, _) = await montarDialogo(
      tester,
      responder: (r) => r.method == 'POST'
          ? http.Response('survey already submitted for this event', 409)
          : http.Response(jsonEncode(encuestaGuardada), 200),
    );

    final estrellas = find.descendant(
      of: find.byKey(const Key('survey-overall')),
      matching: find.byIcon(Icons.star_rounded),
    );
    await tester.tap(estrellas.at(3));
    await tester.pump();

    await tester.tap(find.byKey(const Key('survey-submit')));
    await tester.pumpAndSettle();

    expect(provider.mySurveyFor('event-1'), isNotNull);
    expect(provider.mySurveyFor('event-1')!.overallRating, 5);
  });

  testWidgets('Con encuesta previa muestra lo respondido, no el formulario', (
    tester,
  ) async {
    final enviados = <String>[];
    final client = MockClient((request) async {
      if (request.method == 'POST') enviados.add(request.body);
      return http.Response(jsonEncode(encuestaGuardada), 200);
    });

    final provider = EventsProvider(
      eventService: EventService(client: client),
    );
    final auth = _AuthConToken();

    await provider.loadMyEventSurvey(
      eventId: 'event-1',
      token: 'token-de-prueba',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<EventsProvider>.value(value: provider),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: EventSurveyDialog(
              eventId: 'event-1',
              eventTitle: 'LEGACY SUMMIT 2026',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ya enviaste tu opinión'), findsOneWidget);
    expect(find.byKey(const Key('survey-submit')), findsNothing);
    expect(find.text('Todo excelente'), findsOneWidget);
    expect(enviados, isEmpty);
  });

  group('EventsProvider.loadMyEventSurvey', () {
    test('Un 204 deja el estado sin encuesta pero marcado como consultado', () async {
      final provider = EventsProvider(
        eventService: EventService(
          client: MockClient((_) async => http.Response('', 204)),
        ),
      );

      final survey = await provider.loadMyEventSurvey(
        eventId: 'event-1',
        token: 'token',
      );

      expect(survey, isNull);
      expect(provider.mySurveyFor('event-1'), isNull);
      expect(provider.hasCheckedSurvey('event-1'), isTrue);
    });

    test('Un fallo de red no rompe la pantalla', () async {
      // No poder comprobar el estado no debe impedir que el detalle se dibuje.
      final provider = EventsProvider(
        eventService: EventService(
          client: MockClient((_) async => http.Response('boom', 500)),
        ),
      );

      final survey = await provider.loadMyEventSurvey(
        eventId: 'event-1',
        token: 'token',
      );

      expect(survey, isNull);
      expect(provider.hasCheckedSurvey('event-1'), isFalse);
    });
  });
}
