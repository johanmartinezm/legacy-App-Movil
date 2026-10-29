import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:legacy_app/data/config/config_service.dart';
import 'package:legacy_app/data/services/event_service.dart';
import 'package:legacy_app/domain/providers/auth_provider.dart';
import 'package:legacy_app/domain/providers/events_provider.dart';
import 'package:legacy_app/presentation/widgets/eventos/rating_dialog.dart';
import 'package:provider/provider.dart';

class _AuthFake extends AuthProvider {
  @override
  String? get token => 'token-de-prueba';
}

/// Cuando el servidor rechaza la calificación de forma definitiva («ya
/// calificaste este taller») el diálogo se cierra: antes se quedaba abierto y
/// el mensaje salía detrás, invitando a reintentar algo que no iba a cambiar.
/// Ante un fallo de conexión, en cambio, sigue abierto para poder reintentar.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await ConfigService.initialize();
  });

  Future<void> calificar(WidgetTester tester, MockClient client) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

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
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) =>
                      const RatingDialog(itemName: 'Taller', itemId: 'ws-1'),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.star_rounded).last);
    await tester.pump();
    await tester.tap(find.text('Enviar Calificación'));
    await tester.pumpAndSettle();
  }

  testWidgets('Ya calificado: el diálogo se cierra y explica el motivo', (
    tester,
  ) async {
    await calificar(
      tester,
      MockClient((_) async => http.Response('ya calificaste este taller', 409)),
    );

    expect(find.byType(RatingDialog), findsNothing);
    expect(find.text('ya calificaste este taller'), findsOneWidget);
  });

  testWidgets('Sin conexión: el diálogo sigue abierto para reintentar', (
    tester,
  ) async {
    await calificar(
      tester,
      MockClient((_) async => throw Exception('sin red')),
    );

    expect(find.byType(RatingDialog), findsOneWidget);
  });
}
