import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:legacy_app/data/config/config_service.dart';
import 'package:legacy_app/data/services/beneficios_service.dart';
import 'package:legacy_app/domain/providers/auth_provider.dart';
import 'package:legacy_app/presentation/screens/beneficios/beneficios_screen.dart';
import 'package:provider/provider.dart';

/// Sección Beneficios: solo usuarios Legacy+, con dos sliders (beneficios y
/// alianzas) y su propio contenido del panel.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await ConfigService.initialize();
  });

  Future<void> montar(WidgetTester tester, http.Client cliente) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ChangeNotifierProvider<AuthProvider>(
      create: (_) => AuthProvider(),
      child: MaterialApp(home: BeneficiosScreen(servicio: BeneficiosService(client: cliente))),
    ));
    await tester.pump();
    await tester.pump();
  }

  http.Client json200(Object cuerpo) => MockClient(
      (_) async => http.Response.bytes(utf8.encode(jsonEncode(cuerpo)), 200));

  testWidgets('dos sliders: beneficios y alianzas, cada uno con lo suyo', (tester) async {
    await montar(
      tester,
      json200([
        {'tipo': 'alianza', 'titulo': 'JW Marriott', 'descripcion': 'Tarifa especial'},
        {'tipo': 'beneficio', 'titulo': 'Legacy Test', 'descripcion': 'Con descuento', 'enlace_url': 'https://x.co'},
      ]),
    );
    expect(find.text('BENEFICIOS'), findsOneWidget);
    expect(find.text('ALIANZAS'), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('slider-beneficios')), matching: find.text('Legacy Test')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('slider-alianzas')), matching: find.text('JW Marriott')), findsOneWidget);
    // Solo la tarjeta con enlace lleva el botón.
    expect(find.text('Ver más'), findsOneWidget);
  });

  testWidgets('sin alianzas, solo el slider de beneficios', (tester) async {
    await montar(tester, json200([
      {'tipo': 'beneficio', 'titulo': 'Legacy Test'},
    ]));
    expect(find.text('BENEFICIOS'), findsOneWidget);
    expect(find.text('ALIANZAS'), findsNothing);
  });

  testWidgets('sin nada publicado, un aviso', (tester) async {
    await montar(tester, json200([]));
    expect(find.text('Pronto publicaremos los beneficios.'), findsOneWidget);
  });

  testWidgets('sin Legacy+: el 403 se explica', (tester) async {
    await montar(tester, MockClient((_) async => http.Response('Esta sección es para usuarios Legacy+.', 403)));
    expect(find.text('Esta sección es para usuarios Legacy+.'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });

  testWidgets('sin red: aviso de conexión, no el de Legacy+', (tester) async {
    await montar(tester, MockClient((_) async => http.Response('boom', 500)));
    expect(find.textContaining('Revisa tu conexión'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsNothing);
  });
}
