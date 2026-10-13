import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:legacy_app/data/config/config_service.dart';
import 'package:legacy_app/data/services/legacy_plus_service.dart';
import 'package:legacy_app/data/services/secciones_inicio_service.dart';
import 'package:legacy_app/domain/providers/auth_provider.dart';
import 'package:legacy_app/presentation/screens/beneficios/beneficios_screen.dart';
import 'package:provider/provider.dart';

/// Sección Beneficios: solo para usuarios Legacy+. El backend lo valida y la
/// pantalla explica el 403 en vez de mostrar un error.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await ConfigService.initialize();
  });

  Future<void> montar(WidgetTester tester, http.Client puntos) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ChangeNotifierProvider<AuthProvider>(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        home: BeneficiosScreen(
          puntosService: LegacyPlusService(client: puntos),
          textosService: SeccionesInicioService(
            client: MockClient((_) async => http.Response('[]', 200)),
          ),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('usuario Legacy+: los beneficios con su texto', (tester) async {
    await montar(
      tester,
      MockClient((_) async => http.Response.bytes(
            utf8.encode(jsonEncode([
              {'grupo': 'beneficios', 'titulo': 'Legacy Network', 'texto': 'LSO 15%'},
              {'grupo': 'beneficios', 'titulo': 'Aliados', 'texto': 'Vitalea'},
            ])),
            200,
          )),
    );
    expect(find.text('BENEFICIOS'), findsOneWidget);
    expect(find.text('Legacy Network'), findsOneWidget);
    expect(find.text('LSO 15%'), findsOneWidget);
    expect(find.text('Vitalea'), findsOneWidget);
  });

  testWidgets('sin Legacy+: el 403 se explica', (tester) async {
    await montar(
      tester,
      MockClient((_) async => http.Response('Esta sección es para usuarios Legacy+.', 403)),
    );
    expect(find.text('Esta sección es para usuarios Legacy+.'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });

  testWidgets('sin red: aviso de conexión, no el de Legacy+', (tester) async {
    await montar(tester, MockClient((_) async => http.Response('boom', 500)));
    expect(find.textContaining('Revisa tu conexión'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsNothing);
  });
}
