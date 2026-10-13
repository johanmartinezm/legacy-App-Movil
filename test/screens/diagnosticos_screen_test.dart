import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:legacy_app/presentation/screens/diagnosticos/diagnosticos_screen.dart';

/// Diagnósticos: dos botones, cada uno hacia su diagnóstico en la web.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('muestra los dos diagnósticos con sus enlaces', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DiagnosticosScreen()));

    expect(find.text('Diagnóstico para familias empresarias'), findsOneWidget);
    expect(find.text('Diagnóstico para empresas y organizaciones'), findsOneWidget);
    expect(
      find.byKey(const Key('diagnostico-https://legacynetworkco.com/legacy-test/?v=ab6c04006660')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('diagnostico-https://certificaciongc.legacynetworkco.com/')),
      findsOneWidget,
    );
  });
}
