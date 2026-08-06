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
import 'package:legacy_app/presentation/screens/eventos/event_payment_screen.dart';
import 'package:provider/provider.dart';

/// Sesión iniciada con datos de perfil. `AuthProvider` los lee de
/// `flutter_secure_storage`, que no está disponible en las pruebas, así que se
/// sustituyen los getters.
class _AuthFake extends AuthProvider {
  final String? nombre;
  final String? correo;
  final String? telefono;

  _AuthFake({this.nombre, this.correo, this.telefono});

  @override
  String? get token => 'token-de-prueba';
  @override
  String? get fullName => nombre;
  @override
  String? get email => correo;
  @override
  String? get phone => telefono;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final evento = EventModel.fromJson({
    'id': 'event-1',
    'title': 'LEGACY SUMMIT 2026',
    'category': 'summit',
    'date': '2026-10-15T00:00:00Z',
    'location': 'Cancún',
    'price': 250000,
    'isFree': false,
    'actionStatus': '',
    'buttonText': 'Comprar',
    'description': '',
  });

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await ConfigService.initialize();
  });

  /// Devuelve las peticiones que llegaron al backend, para poder afirmar sobre
  /// lo que salió de verdad por la red.
  Future<List<String>> montar(WidgetTester tester, AuthProvider auth) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final llamadas = <String>[];
    final client = MockClient((request) async {
      llamadas.add('${request.method} ${request.url.path}');
      return http.Response('{"id":"reg-1","payment_status":"pending"}', 201);
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<EventsProvider>(
            create: (_) => EventsProvider(
              eventService: EventService(client: client),
            ),
          ),
        ],
        child: MaterialApp(home: EventPaymentScreen(event: evento)),
      ),
    );
    await tester.pumpAndSettle();
    return llamadas;
  }

  String valorDe(WidgetTester tester, String clave) {
    return tester.widget<TextFormField>(find.byKey(Key(clave))).controller!.text;
  }

  testWidgets('Prellena los datos del participante con los del usuario', (
    tester,
  ) async {
    await montar(
      tester,
      _AuthFake(
        nombre: 'Johan Martinez',
        correo: 'johan@example.com',
        telefono: '+57 300 123 4567',
      ),
    );

    expect(valorDe(tester, 'pago-nombre'), 'Johan Martinez');
    expect(valorDe(tester, 'pago-email'), 'johan@example.com');
    expect(valorDe(tester, 'pago-telefono'), '+57 300 123 4567');
  });

  testWidgets('Con perfil incompleto deja el campo vacío, no el texto de ejemplo', (
    tester,
  ) async {
    // El "Juan Perez Garcia" que se veía antes era el hint, no un valor: si
    // llegara a enviarse sería el nombre de otra persona.
    await montar(
      tester,
      _AuthFake(nombre: 'Johan Martinez', correo: 'johan@example.com'),
    );

    expect(valorDe(tester, 'pago-telefono'), isEmpty);
    expect(valorDe(tester, 'pago-nombre'), 'Johan Martinez');
  });

  testWidgets('Los campos son editables y conservan lo que se escribe', (
    tester,
  ) async {
    await montar(
      tester,
      _AuthFake(
        nombre: 'Johan Martinez',
        correo: 'johan@example.com',
        telefono: '+57 300 123 4567',
      ),
    );

    await tester.enterText(
      find.byKey(const Key('pago-nombre')),
      'Otro Participante',
    );
    await tester.pump();

    expect(valorDe(tester, 'pago-nombre'), 'Otro Participante');
  });

  testWidgets('No procede al pago con campos vacíos', (tester) async {
    await montar(tester, _AuthFake());

    await tester.tap(find.text('PROCEDER AL PAGO'));
    await tester.pumpAndSettle();

    expect(find.text('Escribe el nombre del participante'), findsOneWidget);
    expect(find.text('Escribe un correo'), findsOneWidget);
    expect(find.text('Escribe un teléfono de contacto'), findsOneWidget);
  });

  testWidgets('Reserva el cupo antes de salir a la pasarela', (tester) async {
    // El evento es de pago, así que el backend deja la inscripción en
    // 'pending_payment'. Sin esta llamada no quedaría ni rastro de quién
    // intentó comprar: antes la app iba directa a la pasarela.
    final llamadas = await montar(
      tester,
      _AuthFake(
        nombre: 'Johan Martinez',
        correo: 'johan@example.com',
        telefono: '+57 300 123 4567',
      ),
    );

    await tester.tap(find.text('PROCEDER AL PAGO'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      llamadas,
      contains('POST /api/events/${evento.id}/register'),
      reason: 'la inscripción debe crearse antes de abrir la pasarela',
    );
  });

  testWidgets('Sin datos válidos no reserva ni sale a la pasarela', (
    tester,
  ) async {
    final llamadas = await montar(tester, _AuthFake());

    await tester.tap(find.text('PROCEDER AL PAGO'));
    await tester.pumpAndSettle();

    expect(llamadas, isEmpty);
  });

  testWidgets('Rechaza un correo con errata', (tester) async {
    await montar(
      tester,
      _AuthFake(
        nombre: 'Johan Martinez',
        correo: 'johan@example.com',
        telefono: '+57 300 123 4567',
      ),
    );

    await tester.enterText(find.byKey(const Key('pago-email')), 'johan.example');
    await tester.tap(find.text('PROCEDER AL PAGO'));
    await tester.pumpAndSettle();

    expect(find.text('Ese correo no parece válido'), findsOneWidget);
  });
}
