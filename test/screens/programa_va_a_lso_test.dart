import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:legacy_app/domain/models/program_model.dart';
import 'package:legacy_app/presentation/screens/programs/program_detail_screen.dart';

/// Los programas son de LSO: se cobran en dólares y tienen su propio proceso de
/// inscripción, así que la app lleva a su página en vez de meterlos al carrito
/// —que además los sumaba como pesos y les aplicaba IVA colombiano—.
/// Decisión del cliente del 2026-08-19.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  GraphqlProgram programa({String? url}) => GraphqlProgram(
    id: '1',
    name: 'Certificación Internacional en Gobierno Corporativo',
    shortDescription: 'Programa de gobierno corporativo',
    price: '\$2.500',
    url: url,
  );

  Future<void> montar(WidgetTester tester, GraphqlProgram p) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, _) => ProgramDetailScreen(program: p)),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('el botón dice a dónde lleva', (tester) async {
    await montar(tester, programa(url: 'https://lso.school/programas/certificacion/'));

    expect(find.text('Inscribirme en LSO'), findsOneWidget);
    // Ya no se ofrece comprarlo dentro de la app.
    expect(find.text('Inscribirme'), findsNothing);
    expect(find.textContaining('carrito'), findsNothing);
  });

  testWidgets('sin enlace, el toque no se queda mudo', (tester) async {
    await montar(tester, programa(url: null));

    await tester.ensureVisible(find.text('Inscribirme en LSO'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inscribirme en LSO'));
    // Un pump para el microtask del método async y otro para que el aviso
    // termine de aparecer.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.textContaining('No pudimos abrir la página del programa'),
      findsOneWidget,
    );
    expect(find.textContaining('lso.school'), findsOneWidget);
  });
}
