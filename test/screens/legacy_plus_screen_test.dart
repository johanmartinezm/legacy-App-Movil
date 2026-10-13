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
import 'package:legacy_app/presentation/screens/legacy_plus/legacy_plus_screen.dart';
import 'package:provider/provider.dart';

/// La pantalla Legacy+ toma del panel sus textos fijos y sus puntos con check;
/// sin backend, o con un grupo vacío, se ve lo de siempre.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await ConfigService.initialize();
  });

  http.Client json200(Object cuerpo) => MockClient(
      (_) async => http.Response.bytes(utf8.encode(jsonEncode(cuerpo)), 200));
  http.Client falla() => MockClient((_) async => http.Response('boom', 500));

  Future<void> montar(WidgetTester tester, {required http.Client textos, required http.Client puntos, bool esPlus = false}) async {
    tester.view.physicalSize = const Size(1080, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ChangeNotifierProvider<AuthProvider>(
      create: (_) => esPlus ? _AuthPlus() : AuthProvider(),
      child: MaterialApp(
        home: LegacyPlusScreen(
          textosService: SeccionesInicioService(client: textos),
          puntosService: LegacyPlusService(client: puntos),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('sin backend, lo de siempre', (tester) async {
    await montar(tester, textos: falla(), puntos: falla());
    expect(find.text('LEGACY+'), findsOneWidget);
    expect(find.text('BENEFICIOS'), findsOneWidget);
    for (final p in PuntoLegacyPlus.porDefecto) {
      expect(find.text(p.titulo), findsOneWidget);
    }
    // Nada de lo retirado.
    expect(find.textContaining('YA TIENE LEGACY+'), findsNothing);
    expect(find.textContaining('1.790.000'), findsNothing);
  });

  testWidgets('textos y puntos del panel', (tester) async {
    await montar(
      tester,
      textos: json200([
        {'slug': 'lp-banner', 'titulo': 'Club Legacy', 'texto': 'Para socios', 'imagen_url': ''},
        {'slug': 'lp-beneficios', 'titulo': 'VENTAJAS', 'texto': '', 'imagen_url': ''},
      ]),
      puntos: json200([
        {'grupo': 'incluye', 'titulo': 'Foros', 'texto': 'Debates'},
        {'grupo': 'beneficios', 'titulo': 'Aliado X', 'texto': '20%'},
      ]),
    );
    expect(find.text('Club Legacy'), findsOneWidget);
    expect(find.text('Para socios'), findsOneWidget);
    expect(find.text('VENTAJAS'), findsOneWidget);
    expect(find.text('Foros'), findsOneWidget);
    expect(find.text('Aliado X'), findsOneWidget);
    // Los de siempre ya no.
    expect(find.text('Chats de sinergia'), findsNothing);
    expect(find.text('Beneficios de aliados'), findsNothing);
    // «Cómo accedo» no vino del panel: el de siempre.
    expect(find.textContaining('Cómo accedo'), findsOneWidget);
  });

  testWidgets('un grupo sin puntos activos muestra los de siempre', (tester) async {
    await montar(
      tester,
      textos: falla(),
      puntos: json200([
        {'grupo': 'incluye', 'titulo': 'Foros', 'texto': 'Debates'},
      ]),
    );
    expect(find.text('Foros'), findsOneWidget);
    expect(find.text('Legacy Network'), findsOneWidget);
  });

  testWidgets('usuario Legacy+: sus tres accesos en lugar de lo informativo', (tester) async {
    await montar(tester, textos: falla(), puntos: falla(), esPlus: true);
    expect(find.text('TU ACCESO LEGACY+'), findsOneWidget);
    expect(find.text('Chats de sinergia'), findsOneWidget);
    expect(find.text('Legacy Board'), findsOneWidget);
    expect(find.text('Beneficios'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNWidgets(3));
    // Lo informativo no.
    expect(find.textContaining('Cómo accedo'), findsNothing);
    expect(find.text('Beneficios de aliados'), findsNothing);
  });

  testWidgets('usuario sin Legacy+: lo informativo, sin accesos', (tester) async {
    await montar(tester, textos: falla(), puntos: falla());
    expect(find.text('TU ACCESO LEGACY+'), findsNothing);
    expect(find.textContaining('Cómo accedo'), findsOneWidget);
  });
}

/// Un usuario Legacy+ para las pruebas: el real lo lee de /api/me.
class _AuthPlus extends AuthProvider {
  @override
  bool get esPlus => true;
}
