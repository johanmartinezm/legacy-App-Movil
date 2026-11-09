import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:legacy_app/data/config/config_service.dart';
import 'package:legacy_app/data/services/event_service.dart';
import 'package:legacy_app/domain/models/event_model.dart';
import 'package:legacy_app/domain/models/registration_model.dart';
import 'package:legacy_app/domain/providers/auth_provider.dart';
import 'package:legacy_app/domain/providers/events_provider.dart';
import 'package:legacy_app/presentation/widgets/eventos/event_action_button.dart';
import 'package:provider/provider.dart';

class _AuthFake extends AuthProvider {
  @override
  String? get token => 'token-de-prueba';
}

/// Parte B del plan de workshops: en un evento de pago la app reserva el cupo
/// —queda pendiente— y abre el link de pago; el panel aprueba o rechaza.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const canal = MethodChannel('plugins.flutter.io/url_launcher');
  final abiertos = <String>[];

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await ConfigService.initialize();
    await initializeDateFormatting('es');
  });

  setUp(() {
    abiertos.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canal, (llamada) async {
          if (llamada.method == 'launch') {
            abiertos.add((llamada.arguments as Map)['url'] as String);
          }
          return true;
        });
  });

  String dia(int dentroDe) {
    final d = DateTime.now()
        .toUtc()
        .subtract(const Duration(hours: 5))
        .add(Duration(days: dentroDe));
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  const link = 'https://pagos.example.com/masterclass';

  EventModel evento({int empiezaEn = 30, String? paymentUrl = link}) =>
      EventModel.fromJson({
        'id': 'ev-1',
        'title': 'Masterclass de pago',
        'date': '${dia(empiezaEn)}T00:00:00Z',
        'price': 120,
        'isFree': false,
        'description': '',
        'paymentUrl': paymentUrl,
      });

  Map<String, dynamic> inscripcion(String estado) => {
    'id': 'reg-1',
    'eventId': 'ev-1',
    'eventTitle': 'Masterclass de pago',
    'eventStartDate': '${dia(30)}T00:00:00Z',
    'paymentStatus': 'pending',
    'registrationStatus': estado,
    'qrData': '',
    'totalPaid': 0,
    'attendanceConfirmed': false,
  };

  late List<http.Request> peticiones;

  Future<void> montar(
    WidgetTester tester,
    EventModel e, {
    List<Map<String, dynamic>> inscripciones = const [],
    http.Response? alInscribir,
  }) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    peticiones = [];

    final client = MockClient((request) async {
      peticiones.add(request);
      final p = request.url.path;
      if (p.contains('/registrations')) {
        return http.Response(jsonEncode(inscripciones), 200);
      }
      if (p.endsWith('/register')) {
        return alInscribir ?? http.Response('{"id":"reg-1"}', 201);
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
          home: Scaffold(body: EventActionButton(event: e)),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
  }

  int inscripcionesEnviadas() =>
      peticiones.where((r) => r.url.path.endsWith('/register')).length;

  testWidgets('reservar inscribe y abre el link de pago fuera de la app', (
    tester,
  ) async {
    await montar(tester, evento());

    await tester.tap(find.byKey(const Key('evento-reservar')));
    await tester.pumpAndSettle();

    expect(inscripcionesEnviadas(), 1);
    expect(abiertos, [link]);
    expect(find.textContaining('Tu cupo quedó reservado'), findsOneWidget);
  });

  testWidgets('con el cupo lleno no abre el link y dice por qué', (
    tester,
  ) async {
    await montar(
      tester,
      evento(),
      alInscribir: http.Response('ya no quedan cupos para este evento\n', 409),
    );

    await tester.tap(find.byKey(const Key('evento-reservar')));
    await tester.pumpAndSettle();

    expect(abiertos, isEmpty);
    expect(find.text('Ya no quedan cupos para este evento'), findsOneWidget);
  });

  testWidgets(
    'pendiente: el pago está por confirmar y se puede reabrir el link',
    (tester) async {
      await montar(
        tester,
        evento(),
        inscripciones: [inscripcion('pending_payment')],
      );

      expect(find.text('CUPO RESERVADO · PAGO POR CONFIRMAR'), findsOneWidget);
      await tester.tap(find.text('Abrir el link de pago'));
      await tester.pumpAndSettle();
      expect(abiertos, [link]);
    },
  );

  testWidgets('rechazada: lo dice y deja reservar de nuevo', (tester) async {
    await montar(tester, evento(), inscripciones: [inscripcion('rejected')]);

    expect(find.text('PAGO NO CONFIRMADO'), findsOneWidget);
    await tester.tap(find.byKey(const Key('evento-reservar-de-nuevo')));
    await tester.pumpAndSettle();
    expect(inscripcionesEnviadas(), 1);
    expect(abiertos, [link]);
  });

  testWidgets(
    'rechazada desde el panel con la sesión ya cargada: el detalle la ve',
    (tester) async {
      // Lo que pasa al tocar el aviso de rechazo: las inscripciones ya se
      // habían cargado como pendientes y el detalle se abre sin reiniciar la
      // app. Hasta el 2026-11-09 no se recargaban y seguía «por confirmar».
      var estado = 'pending_payment';
      final client = MockClient((request) async {
        if (request.url.path.contains('/registrations')) {
          return http.Response(jsonEncode([inscripcion(estado)]), 200);
        }
        return http.Response('[]', 200);
      });
      final provider = EventsProvider(
        eventService: EventService(client: client),
      );
      await provider.loadMyRegistrations('token-de-prueba');
      expect(provider.registrationsLoaded, isTrue);

      estado = 'rejected';
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(create: (_) => _AuthFake()),
            ChangeNotifierProvider<EventsProvider>.value(value: provider),
          ],
          child: MaterialApp(
            home: Scaffold(body: EventActionButton(event: evento())),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('PAGO NO CONFIRMADO'), findsOneWidget);
      expect(find.text('CUPO RESERVADO · PAGO POR CONFIRMAR'), findsNothing);
    },
  );

  testWidgets('rechazada con el evento ya empezado: inscripciones cerradas', (
    tester,
  ) async {
    await montar(
      tester,
      evento(empiezaEn: 0),
      inscripciones: [inscripcion('rejected')],
    );
    expect(
      find.byKey(const Key('evento-inscripciones-cerradas')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('evento-reservar-de-nuevo')), findsNothing);
  });

  test('una rechazada no enseña credencial aunque traiga código', () {
    final reg = RegistrationModel.fromJson(
      inscripcion('rejected')..['qrData'] = 'REG-x',
    );
    expect(reg.estaRechazada, isTrue);
    expect(reg.sinAcceso, isTrue);
    expect(reg.tieneQr, isFalse);
  });

  test('el link de pago se lee del evento, y vacío es «no hay»', () {
    expect(evento().paymentUrl, link);
    expect(evento(paymentUrl: '  ').paymentUrl, isNull);
  });
}
