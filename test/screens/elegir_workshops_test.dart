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
import 'package:legacy_app/domain/providers/auth_provider.dart';
import 'package:legacy_app/domain/providers/events_provider.dart';
import 'package:legacy_app/presentation/screens/eventos/cronograma_screen.dart';
import 'package:legacy_app/presentation/widgets/eventos/event_action_button.dart';
import 'package:provider/provider.dart';

class _AuthFake extends AuthProvider {
  @override
  String? get token => 'token-de-prueba';
}

/// §10 del plan de workshops (2026-11-05): al tocar «Reservar cupo» se elige un
/// workshop por franja y después se termina la inscripción; se cambian hasta el
/// día anterior; desde el primer día, la app ya no inscribe.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await ConfigService.initialize();
    await initializeDateFormatting('es');
  });

  // Fechas relativas a hoy, en hora de Colombia: con fechas fijas la elección
  // «abierta» dejaría de estarlo con el paso de los días.
  String dia(int dentroDe) {
    final d = DateTime.now()
        .toUtc()
        .subtract(const Duration(hours: 5))
        .add(Duration(days: dentroDe));
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> ws(
    String id,
    String nombre,
    int enDias,
    String desde,
    String hasta,
  ) => {
    'id': id,
    'eventId': 'event-1',
    'name': nombre,
    'room': 'Sala',
    'speaker': 'Ponente',
    'startDateTime': '${dia(enDias)}T$desde:00-05:00',
    'endDateTime': '${dia(enDias)}T$hasta:00-05:00',
  };

  // Dos franjas: A y B se cruzan en parte; C va sola.
  List<Map<String, dynamic>> dosFranjas(int enDias) => [
    ws('a', 'Gobierno familiar', enDias, '09:00', '10:30'),
    ws('b', 'Protocolo', enDias, '09:30', '11:00'),
    ws('c', 'Plenaria', enDias, '11:00', '12:00'),
  ];

  EventModel evento({
    required int empiezaEn,
    List<Map<String, dynamic>>? workshops,
  }) => EventModel.fromJson({
    'id': 'event-1',
    'title': 'Evento con workshops',
    'date': '${dia(empiezaEn)}T00:00:00Z',
    'price': 0,
    'isFree': true,
    'description': '',
    'workshops': workshops ?? dosFranjas(empiezaEn),
  });

  late List<http.Request> peticiones;

  Future<void> montar(
    WidgetTester tester,
    Widget hijo, {
    List<Map<String, dynamic>> inscripciones = const [],
    List<Map<String, dynamic>> agenda = const [],
  }) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    peticiones = [];

    final client = MockClient((request) async {
      peticiones.add(request);
      final p = request.url.path;
      if (p.contains('/registrations'))
        return http.Response(jsonEncode(inscripciones), 200);
      if (p.endsWith('/events/agenda'))
        return http.Response(jsonEncode(agenda), 200);
      if (p.endsWith('/register')) return http.Response('{"id":"reg-1"}', 201);
      if (p.endsWith('/workshops/mine')) {
        final ids = (jsonDecode(request.body)['workshops'] as List)
            .cast<String>();
        return http.Response(
          jsonEncode(
            dosFranjas(30).where((w) => ids.contains(w['id'])).toList(),
          ),
          200,
        );
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
        child: MaterialApp(home: Scaffold(body: hijo)),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
  }

  bool botonActivo(WidgetTester tester) =>
      tester
          .widget<ElevatedButton>(find.byKey(const Key('selector-continuar')))
          .onPressed !=
      null;

  testWidgets(
    'Reservar abre la hoja y no deja continuar hasta elegir en cada franja',
    (tester) async {
      await montar(tester, EventActionButton(event: evento(empiezaEn: 30)));

      await tester.tap(find.byKey(const Key('evento-reservar')));
      await tester.pumpAndSettle();

      expect(find.text('Elige tus workshops'), findsOneWidget);
      // La plenaria está sola en su franja y sale ya marcada; falta la primera.
      expect(find.byKey(const Key('selector-motivo')), findsOneWidget);
      expect(botonActivo(tester), isFalse);

      await tester.tap(find.byKey(const Key('workshop-b')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('selector-motivo')), findsNothing);
      expect(botonActivo(tester), isTrue);

      await tester.tap(find.byKey(const Key('selector-continuar')));
      await tester.pumpAndSettle();

      final registro = peticiones.singleWhere(
        (r) => r.url.path.endsWith('/register'),
      );
      final ids = (jsonDecode(registro.body)['workshops'] as List).toSet();
      expect(ids, {'b', 'c'});
    },
  );

  testWidgets('Cerrar la hoja sin continuar no inscribe', (tester) async {
    await montar(tester, EventActionButton(event: evento(empiezaEn: 30)));

    await tester.tap(find.byKey(const Key('evento-reservar')));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10)); // fuera de la hoja
    await tester.pumpAndSettle();

    expect(peticiones.where((r) => r.url.path.endsWith('/register')), isEmpty);
  });

  testWidgets('Un evento sin workshops se reserva como siempre, sin hoja', (
    tester,
  ) async {
    await montar(
      tester,
      EventActionButton(event: evento(empiezaEn: 30, workshops: [])),
    );

    await tester.tap(find.byKey(const Key('evento-reservar')));
    await tester.pumpAndSettle();

    expect(find.text('Elige tus workshops'), findsNothing);
    expect(
      peticiones.where((r) => r.url.path.endsWith('/register')),
      hasLength(1),
    );
  });

  testWidgets('Desde el primer día las inscripciones están cerradas', (
    tester,
  ) async {
    await montar(tester, EventActionButton(event: evento(empiezaEn: 0)));

    expect(
      find.byKey(const Key('evento-inscripciones-cerradas')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('evento-reservar')), findsNothing);
  });

  Map<String, dynamic> inscrito() => {
    'id': 'reg-1',
    'eventId': 'event-1',
    'eventTitle': 'Evento con workshops',
    'eventStartDate': '${dia(30)}T00:00:00Z',
    'paymentStatus': 'free',
    'registrationStatus': 'confirmed',
    'qrData': 'REG-x',
    'totalPaid': 0,
    'attendanceConfirmed': false,
  };

  testWidgets('Inscrito: cambia sus workshops hasta el día anterior', (
    tester,
  ) async {
    await montar(
      tester,
      EventActionButton(event: evento(empiezaEn: 30)),
      inscripciones: [inscrito()],
      agenda: [dosFranjas(30)[0], dosFranjas(30)[2]],
    );

    expect(find.text('Mis workshops · cambiar'), findsOneWidget);
    await tester.tap(find.byKey(const Key('evento-mis-workshops')));
    await tester.pumpAndSettle();

    // Viene marcada su elección: se puede guardar sin tocar nada.
    expect(botonActivo(tester), isTrue);
    await tester.tap(find.byKey(const Key('workshop-b')));
    await tester.tap(find.byKey(const Key('selector-continuar')));
    await tester.pumpAndSettle();

    final cambio = peticiones.singleWhere(
      (r) => r.url.path.endsWith('/workshops/mine'),
    );
    expect(cambio.method, 'PUT');
    expect((jsonDecode(cambio.body)['workshops'] as List).toSet(), {'b', 'c'});
    expect(find.text('Guardamos tus workshops.'), findsOneWidget);
  });

  testWidgets('El día del evento solo se ven, sin poder cambiarlos', (
    tester,
  ) async {
    await montar(
      tester,
      EventActionButton(event: evento(empiezaEn: 0)),
      inscripciones: [inscrito()],
      agenda: [dosFranjas(0)[0], dosFranjas(0)[2]],
    );

    expect(find.text('Mis workshops'), findsOneWidget);
    await tester.tap(find.byKey(const Key('evento-mis-workshops')));
    await tester.pumpAndSettle();

    expect(
      find.text('La elección cerró al empezar el evento.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('selector-continuar')), findsNothing);
    expect(find.text('Protocolo'), findsNothing); // el no elegido no se lista
  });

  testWidgets('En el cronograma: marca lo elegido y solo deja calificar eso', (
    tester,
  ) async {
    // Un evento que ya pasó, con los dos workshops de la primera franja
    // terminados; eligió A.
    final pasados = dosFranjas(-2);
    await montar(
      tester,
      CronogramaScreen(event: evento(empiezaEn: -2, workshops: pasados)),
      agenda: [pasados[0], pasados[2]],
    );
    // La agenda la carga el listado de eventos; aquí se pide a mano.
    final ctx = tester.element(find.byType(CronogramaScreen));
    await ctx.read<EventsProvider>().loadAgenda('token-de-prueba');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('elegido-a')), findsOneWidget);
    expect(find.byKey(const Key('elegido-b')), findsNothing);
    // Se ofrece calificar A y C, no B.
    expect(find.text('Calificar experiencia'), findsNWidgets(2));
  });

  test(
    'El motivo del servidor llega legible, aunque venga en texto plano',
    () async {
      final servicio = EventService(
        client: MockClient(
          (_) async => http.Response(
            'falta elegir un workshop el 10/12 de 11:00 a 12:00\n',
            400,
          ),
        ),
      );
      expect(
        () => servicio.registerToEvent('event-1', 'token', workshops: ['a']),
        throwsA(
          isA<MotivoDelServidor>().having(
            (e) => e.mensaje,
            'mensaje',
            'Falta elegir un workshop el 10/12 de 11:00 a 12:00',
          ),
        ),
      );
    },
  );
}
