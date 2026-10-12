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
import 'package:legacy_app/presentation/screens/eventos/event_purchase_detail_screen.dart';
import 'package:provider/provider.dart';

class _AuthFake extends AuthProvider {
  @override
  String? get token => 'token-de-prueba';
}

/// La ficha del detalle de un evento mostraba en TODOS los eventos el modelo
/// DINASTÍA, el acceso a Legacy+ y la nota de alumni del Summit, y cuando el
/// evento no traía «Incluye» ni speakers ponía los del Summit. Una masterclass
/// anunciaba así el campus de 45 días, el libro y El Espectador.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await ConfigService.initialize();
  });

  EventModel evento(
    String categoria, {
    String? speaker,
    String? includes,
    String? model,
  }) =>
      EventModel.fromJson({
        'id': 'event-1',
        'title': 'Evento de prueba',
        'category': categoria,
        'date': '2026-12-20T00:00:00Z',
        'price': 0,
        'isFree': true,
        'actionStatus': 'register',
        'buttonText': 'Reservar cupo gratis',
        'description': 'Descripción',
        'imageUrl': '',
        'speaker': speaker,
        'includes': includes,
        'model': model,
      });

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

  testWidgets('Masterclass sin datos: nada del Summit ni ficha vacía', (
    tester,
  ) async {
    await montar(tester, evento('masterclass'));

    expect(find.text('Speakers'), findsNothing);
    expect(find.text('Modelo'), findsNothing);
    expect(find.text('Incluye'), findsNothing);
    expect(find.textContaining('Campus 45 días'), findsNothing);
    expect(find.text('Alumni Summit'), findsNothing);
    expect(find.textContaining('lo convierte en alumni'), findsNothing);
    expect(find.textContaining('Sanjay Goel'), findsNothing);
  });

  testWidgets('Masterclass con datos: muestra solo los suyos', (tester) async {
    await montar(
      tester,
      evento('masterclass', speaker: 'Johan Martínez', includes: 'Material\nCertificado'),
    );

    expect(find.text('Johan Martínez'), findsOneWidget);
    expect(find.byKey(const Key('ficha-incluye-lista')), findsOneWidget);
    expect(find.text('Material'), findsOneWidget);
    expect(find.text('Certificado'), findsOneWidget);
    expect(find.text('Modelo'), findsNothing);
    expect(find.text('Alumni Summit'), findsNothing);
    expect(find.textContaining('lo convierte en alumni'), findsNothing);
  });

  testWidgets('Summit: conserva modelo, alumni y la nota', (tester) async {
    await montar(
      tester,
      evento(
        'summit',
        speaker: 'Sanjay Goel, Ph.D.',
        model: '7 dimensiones DINASTÍA',
      ),
    );

    expect(find.text('7 dimensiones DINASTÍA'), findsOneWidget);
    expect(find.text('Acceso a Legacy+'), findsOneWidget);
    expect(find.textContaining('lo convierte en alumni'), findsOneWidget);
    expect(find.text('Incluye'), findsNothing);
  });

  testWidgets('El modelo sale del evento, sea cual sea su categoría', (
    tester,
  ) async {
    await montar(tester, evento('masterclass', model: 'Modelo propio'));
    expect(find.text('Modelo'), findsOneWidget);
    expect(find.text('Modelo propio'), findsOneWidget);
  });

  testWidgets('Summit sin modelo cargado: no muestra la fila', (tester) async {
    await montar(tester, evento('summit'));
    expect(find.text('Modelo'), findsNothing);
    expect(find.text('7 dimensiones DINASTÍA'), findsNothing);
  });

  testWidgets('Incluye de un solo ítem va en la fila, no como lista', (
    tester,
  ) async {
    await montar(tester, evento('masterclass', includes: 'Certificado'));
    expect(find.text('Certificado'), findsOneWidget);
    expect(find.byKey(const Key('ficha-incluye-lista')), findsNothing);
  });

  test('itemsDeIncluye quita viñetas escritas y líneas vacías', () {
    expect(
      itemsDeIncluye('- Libro\r\n\n• Campus\n* Coctel\n  Certificado  \n'),
      ['Libro', 'Campus', 'Coctel', 'Certificado'],
    );
    expect(itemsDeIncluye(null), isEmpty);
    expect(itemsDeIncluye('   '), isEmpty);
  });
}
