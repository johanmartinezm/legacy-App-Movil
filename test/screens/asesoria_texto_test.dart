import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:legacy_app/data/config/config_service.dart';
import 'package:legacy_app/data/services/secciones_inicio_service.dart';
import 'package:legacy_app/domain/providers/auth_provider.dart';
import 'package:legacy_app/presentation/screens/asesoria/asesoria_screen.dart';
import 'package:provider/provider.dart';

/// El primer recuadro de Asesoría ya no lleva título y su texto lo edita el
/// panel («Texto de Asesoría»); vacío o sin backend, se ve el de siempre.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await ConfigService.initialize();
  });

  const porDefecto =
      'No necesita ser cliente para empezar. Solicite una propuesta y conozca cómo nuestras cinco unidades pueden acompañarle.';

  SeccionesInicioService servicio(String texto) => SeccionesInicioService(
        client: MockClient((_) async => http.Response.bytes(
              utf8.encode(jsonEncode([
                {'slug': 'asesoria-banner', 'pantalla': 'asesoria', 'imagen_url': '', 'titulo': '', 'texto': texto},
              ])),
              200,
            )),
      );

  Future<void> montar(WidgetTester tester, SeccionesInicioService s) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(),
        child: MaterialApp(home: AsesoriaScreen(seccionesService: s)),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('sin el título «Asesoría abierta a todos»', (tester) async {
    await montar(tester, servicio(''));
    expect(find.text('Asesoría abierta a todos'), findsNothing);
  });

  testWidgets('el texto del panel sustituye al de siempre', (tester) async {
    await montar(tester, servicio('Hablemos de su empresa.'));
    expect(find.text('Hablemos de su empresa.'), findsOneWidget);
    expect(find.text(porDefecto), findsNothing);
  });

  testWidgets('vacío en el panel, el de siempre', (tester) async {
    await montar(tester, servicio(''));
    expect(find.text(porDefecto), findsOneWidget);
  });
}
