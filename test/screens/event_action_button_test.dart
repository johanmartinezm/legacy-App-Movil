import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:legacy_app/data/config/config_service.dart';
import 'package:legacy_app/data/services/event_service.dart';
import 'package:legacy_app/domain/models/event_model.dart';
import 'package:legacy_app/domain/providers/auth_provider.dart';
import 'package:legacy_app/domain/providers/events_provider.dart';
import 'package:legacy_app/presentation/widgets/eventos/event_action_button.dart';
import 'package:provider/provider.dart';

class _AuthFake extends AuthProvider {
  @override
  String? get token => 'token-de-prueba';
}

/// El botón del detalle de un evento decidía si el usuario estaba inscrito con
/// `event.actionStatus == 'registered'`, pero `action_status` es una columna del
/// EVENTO —igual para todos— y el backend solo devuelve `register` o `buy`. La
/// condición no se cumplía nunca: un usuario ya inscrito seguía viendo
/// "Reservar cupo".
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final eventoGratis = EventModel.fromJson({
    'id': 'event-1',
    'title': 'Evento gratuito',
    'category': 'masterclass',
    'date': '2026-12-20T00:00:00Z',
    'price': 0,
    'isFree': true,
    'actionStatus': 'register',
    'buttonText': 'Reservar cupo gratis',
    'description': '',
  });

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await ConfigService.initialize();
  });

  Map<String, dynamic> inscripcionA(String eventId, String estado) => {
        'id': 'reg-1',
        'eventId': eventId,
        'eventTitle': 'Evento gratuito',
        'eventStartDate': '2026-12-20T00:00:00Z',
        'paymentStatus': estado == 'confirmed' ? 'free' : 'pending',
        'registrationStatus': estado,
        'qrData': estado == 'confirmed' ? 'REG-aleatorio' : '',
        'totalPaid': 0,
        'attendanceConfirmed': false,
      };

  Future<void> montar(
    WidgetTester tester, {
    required List<Map<String, dynamic>> inscripciones,
  }) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final client = MockClient((request) async {
      if (request.url.path.contains('/registrations')) {
        return http.Response(jsonEncode(inscripciones), 200);
      }
      return http.Response('{}', 200);
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
          home: Scaffold(body: EventActionButton(event: eventoGratis)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();
  }

  testWidgets('Ya inscrito: no ofrece reservar, y da acceso a la credencial', (
    tester,
  ) async {
    await montar(
      tester,
      inscripciones: [inscripcionA('event-1', 'confirmed')],
    );

    expect(find.byKey(const Key('evento-ya-inscrito')), findsOneWidget);
    expect(find.text('YA ESTÁS REGISTRADO'), findsOneWidget);
    expect(find.text('Ver mi credencial'), findsOneWidget);
    expect(find.byKey(const Key('evento-reservar')), findsNothing);
    expect(find.text('Reservar cupo gratis'), findsNothing);
  });

  testWidgets('No inscrito: ofrece reservar', (tester) async {
    await montar(tester, inscripciones: []);

    expect(find.byKey(const Key('evento-reservar')), findsOneWidget);
    expect(find.text('Reservar cupo gratis'), findsOneWidget);
    expect(find.byKey(const Key('evento-ya-inscrito')), findsNothing);
  });

  testWidgets('Inscrito en otro evento: sigue ofreciendo reservar en este', (
    tester,
  ) async {
    await montar(
      tester,
      inscripciones: [inscripcionA('otro-evento', 'confirmed')],
    );

    expect(find.byKey(const Key('evento-reservar')), findsOneWidget);
  });

  testWidgets('Pendiente de pago: ni reservar ni credencial, sino completar el pago', (
    tester,
  ) async {
    await montar(
      tester,
      inscripciones: [inscripcionA('event-1', 'pending_payment')],
    );

    expect(find.byKey(const Key('evento-pendiente-pago')), findsOneWidget);
    expect(find.text('Completar pago'), findsOneWidget);
    expect(find.byKey(const Key('evento-reservar')), findsNothing);
    expect(find.text('YA ESTÁS REGISTRADO'), findsNothing);
  });
}
