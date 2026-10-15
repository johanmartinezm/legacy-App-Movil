import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:legacy_app/data/config/config_service.dart';
import 'package:legacy_app/data/services/asesoria_unidades_service.dart';
import 'package:legacy_app/domain/providers/auth_provider.dart';
import 'package:legacy_app/presentation/screens/asesoria/asesoria_screen.dart';
import 'package:provider/provider.dart';

/// Pantalla de Asesoría tras los cambios del 2026-10-13: sin el recuadro de
/// bienvenida, con las unidades administradas desde el panel, y con el
/// formulario que pide indicativo, ofrece «Otro» y admite un detalle de hasta
/// 500 palabras.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await ConfigService.initialize();
  });


  /// Sin backend: las pruebas del formulario usan las unidades de siempre.
  AsesoriaUnidadesService sinBackend() => AsesoriaUnidadesService(
        client: MockClient((_) async => http.Response('boom', 500)),
      );

  AsesoriaUnidadesService conUnidades(List<Map<String, dynamic>> unidades) =>
      AsesoriaUnidadesService(
        client: MockClient((_) async =>
            http.Response.bytes(utf8.encode(jsonEncode(unidades)), 200)),
      );

  Future<void> montar(WidgetTester tester, [AsesoriaUnidadesService? servicio]) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(),
        child: MaterialApp(
          home: AsesoriaScreen(unidadesService: servicio ?? sinBackend()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('las unidades salen del panel, en su orden', (tester) async {
    await montar(
      tester,
      conUnidades([
        {'titulo': 'Aurum', 'subtitulo': 'Finanzas', 'icono': 'crecimiento', 'necesidad': 'Patrimonio'},
        {'titulo': 'Nueva unidad', 'subtitulo': 'Recién creada', 'icono': 'cohete', 'necesidad': 'Otro'},
      ]),
    );
    expect(find.text('Aurum'), findsOneWidget);
    expect(find.text('Nueva unidad'), findsOneWidget);
    // Las de siempre ya no.
    expect(find.text('L&M Consultoría'), findsNothing);
    // Un icono desconocido no rompe: se pinta el genérico.
    expect(find.byIcon(Icons.business_center_outlined), findsOneWidget);
  });

  test('la imagen del panel se lee; sin ella queda vacía', () {
    final con = UnidadAsesoria.fromJson({
      'titulo': 'Aurum', 'icono': 'crecimiento', 'necesidad': 'Patrimonio',
      'imagen_url': ' https://example.com/aurum.png ',
    });
    expect(con.imagenUrl, 'https://example.com/aurum.png');
    expect(con.icono, Icons.trending_up);
    final sin = UnidadAsesoria.fromJson({'titulo': 'Aurum', 'icono': 'crecimiento'});
    expect(sin.imagenUrl, isEmpty);
  });

  testWidgets('con imagen se pinta la imagen y no el icono', (tester) async {
    await montar(
      tester,
      conUnidades([
        {'titulo': 'Aurum', 'subtitulo': 'Finanzas', 'icono': 'crecimiento', 'necesidad': 'Patrimonio',
         'imagen_url': 'https://example.com/aurum.png'},
        {'titulo': 'Legal', 'subtitulo': 'Leyes', 'icono': 'balanza', 'necesidad': 'Otro'},
      ]),
    );
    expect(find.byType(CachedNetworkImage), findsOneWidget);
    expect(find.byIcon(Icons.trending_up), findsNothing);
    expect(find.byIcon(Icons.balance), findsOneWidget);
  });

  testWidgets('entrar por una unidad marca su necesidad', (tester) async {
    await montar(
      tester,
      conUnidades([
        {'titulo': 'Aurum', 'subtitulo': 'Finanzas', 'icono': 'crecimiento', 'necesidad': 'Otro'},
      ]),
    );
    await tester.tap(find.text('Aurum'));
    await tester.pumpAndSettle();
    expect(find.text('Solicitar asesoría'), findsOneWidget);
    // El chip elegido se pinta en el color activo.
    final otro = tester.widget<Text>(find.text('Otro'));
    expect(otro.style?.color, isNot(const Color(0xFF9FB2C2)));
  });

  testWidgets('sin backend, las cinco de siempre', (tester) async {
    await montar(tester);
    for (final u in UnidadAsesoria.porDefecto) {
      expect(find.text(u.titulo), findsOneWidget);
    }
  });

  testWidgets('abre con las unidades, sin el recuadro de bienvenida', (tester) async {
    await montar(tester);
    expect(find.textContaining('No necesita ser cliente'), findsNothing);
    expect(find.text('Asesoría abierta a todos'), findsNothing);
    expect(find.text('NUESTRAS UNIDADES'), findsOneWidget);
  });

  testWidgets('las unidades dicen «CONTACTAR» y no hay botón inferior', (tester) async {
    await montar(tester);
    expect(find.text('ABIERTA'), findsNothing);
    expect(find.text('CONTACTAR'), findsWidgets);
    expect(find.text('Solicitar propuesta / agendar'), findsNothing);
  });

  testWidgets('el formulario no promete 48h y ofrece «Otro»', (tester) async {
    await montar(tester);
    await tester.tap(find.text('L&M Consultoría'));
    await tester.pumpAndSettle();

    expect(find.text('Solicitar asesoría'), findsOneWidget);
    expect(find.textContaining('48'), findsNothing);
    expect(find.text('Otro'), findsOneWidget);

    await tester.tap(find.text('Otro'));
    await tester.pump();
  });

  testWidgets('el indicativo del WhatsApp es obligatorio', (tester) async {
    await montar(tester);
    await tester.tap(find.text('L&M Consultoría'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('asesoria-whatsapp')), '300 123 4567');
    await tester.tap(find.text('Enviar solicitud'));
    await tester.pump();
    expect(find.text('Elija el indicativo'), findsOneWidget);

    // Elegido, el aviso desaparece.
    await tester.tap(find.byKey(const Key('asesoria-indicativo')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🇨🇴 Colombia (+57)').last);
    await tester.pumpAndSettle();
    expect(find.text('🇨🇴 +57'), findsOneWidget);
    expect(find.text('Elija el indicativo'), findsNothing);
  });

  testWidgets('un número demasiado corto no pasa', (tester) async {
    await montar(tester);
    await tester.tap(find.text('L&M Consultoría'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('asesoria-whatsapp')), '123');
    await tester.tap(find.text('Enviar solicitud'));
    await tester.pump();
    expect(find.text('Número incompleto'), findsOneWidget);
  });

  testWidgets('el detalle admite hasta 500 palabras', (tester) async {
    await montar(tester);
    await tester.tap(find.text('L&M Consultoría'));
    await tester.pumpAndSettle();

    final campo = find.byKey(const Key('asesoria-detalle'));
    await tester.enterText(campo, List.filled(500, 'palabra').join(' '));
    await tester.pump();
    expect(find.text('500 / 500 palabras'), findsOneWidget);
    expect(find.text('Máximo 500 palabras'), findsNothing);

    await tester.enterText(campo, List.filled(501, 'palabra').join(' '));
    await tester.pump();
    expect(find.text('Máximo 500 palabras'), findsOneWidget);
  });

}
