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
import 'package:legacy_app/presentation/screens/profile/mi_credencial_screen.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Sesión iniciada. `AuthProvider` lee de `flutter_secure_storage`, que no está
/// disponible en las pruebas.
class _AuthFake extends AuthProvider {
  @override
  String? get token => 'token-de-prueba';
  @override
  String? get fullName => 'Johan Martinez';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await ConfigService.initialize();
  });

  Map<String, dynamic> inscripcion({
    required String eventId,
    required String titulo,
    required String estado,
    String qr = 'REG-8f14e45f-ceea-467a-9e83-1c0dc1b3b0f2',
    String fecha = '2026-12-20T00:00:00Z',
    bool asistio = false,
  }) {
    return {
      'id': 'reg-$eventId',
      'eventId': eventId,
      'eventTitle': titulo,
      'eventLocation': 'En linea',
      'eventStartDate': fecha,
      'eventEndDate': fecha,
      'paymentStatus': estado == 'confirmed' ? 'free' : 'pending',
      'registrationStatus': estado,
      'registrationDate': '2026-08-06T01:29:42Z',
      'qrData': estado == 'confirmed' ? qr : '',
      'totalPaid': 0,
      'attendanceConfirmed': asistio,
    };
  }

  Future<void> montar(WidgetTester tester, List<Map<String, dynamic>> datos,
      {int codigo = 200}) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final client = MockClient((request) async {
      return http.Response(jsonEncode(datos), codigo);
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
        child: const MaterialApp(home: MiCredencialScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();
  }

  testWidgets('Muestra un QR por cada evento inscrito', (tester) async {
    // El problema original: solo se alcanzaba el QR del primer taller de la
    // agenda, y solo si la agenda no estaba vacía.
    await montar(tester, [
      inscripcion(eventId: 'e1', titulo: 'LEGACY SUMMIT 2026', estado: 'confirmed'),
      inscripcion(
        eventId: 'e2',
        titulo: 'Coffee & Networking',
        estado: 'confirmed',
        qr: 'REG-otro-codigo-distinto',
      ),
    ]);

    expect(find.text('LEGACY SUMMIT 2026'), findsOneWidget);
    expect(find.text('Coffee & Networking'), findsOneWidget);
    expect(find.byType(QrImageView), findsNWidgets(2));
  });

  testWidgets('Una inscripción pendiente de pago no enseña QR', (tester) async {
    await montar(tester, [
      inscripcion(eventId: 'e1', titulo: 'Evento por pagar', estado: 'pending_payment'),
    ]);

    expect(find.byType(QrImageView), findsNothing);
    expect(find.text('Pendiente de pago'), findsOneWidget);
    expect(find.textContaining('Tu cupo está reservado'), findsOneWidget);
  });

  testWidgets('Distingue las confirmadas de las pendientes en la misma lista', (
    tester,
  ) async {
    await montar(tester, [
      inscripcion(eventId: 'e1', titulo: 'Pagado', estado: 'confirmed'),
      inscripcion(eventId: 'e2', titulo: 'Sin pagar', estado: 'pending_payment'),
    ]);

    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Pendiente de pago'), findsOneWidget);
  });

  testWidgets('Sin inscripciones explica qué hacer, no deja la pantalla vacía', (
    tester,
  ) async {
    await montar(tester, []);

    expect(find.text('Todavía no tienes eventos'), findsOneWidget);
    expect(find.byType(QrImageView), findsNothing);
  });

  testWidgets('Un fallo del servidor se explica y no rompe la pantalla', (
    tester,
  ) async {
    await montar(tester, [], codigo: 500);

    expect(find.text('No pudimos cargar tus credenciales'), findsOneWidget);
  });

  testWidgets('Marca la asistencia ya registrada', (tester) async {
    await montar(tester, [
      inscripcion(
        eventId: 'e1',
        titulo: 'Evento con check-in',
        estado: 'confirmed',
        asistio: true,
      ),
    ]);

    expect(find.text('Asistencia registrada'), findsOneWidget);
  });

  testWidgets('Los eventos pasados van en su propia sección, al final', (
    tester,
  ) async {
    await montar(tester, [
      inscripcion(
        eventId: 'e1',
        titulo: 'Evento por venir',
        estado: 'confirmed',
        fecha: '2026-12-20T00:00:00Z',
      ),
      inscripcion(
        eventId: 'e2',
        titulo: 'Evento terminado',
        estado: 'confirmed',
        fecha: '2026-03-20T00:00:00Z',
      ),
    ]);

    expect(find.text('Eventos pasados'), findsOneWidget);

    final porVenir = tester.getTopLeft(find.byKey(const Key('credencial-e1')));
    final terminado = tester.getTopLeft(find.byKey(const Key('credencial-e2')));
    expect(
      porVenir.dy,
      lessThan(terminado.dy),
      reason: 'lo que sirve para entrar hoy va arriba',
    );
  });
}
