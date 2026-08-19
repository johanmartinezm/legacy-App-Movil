import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:legacy_app/presentation/widgets/custom_section_header.dart';

/// 🔴 La propiedad que hay que preservar: la flecha vuelve a donde estabas.
///
/// El encabezado hace `pop()` si hay algo que desapilar. Con `context.go` no lo
/// hay —go sustituye la pila entera—, así que a las pantallas de detalle se
/// entra con `push`. Cuando de verdad no se puede volver (una notificación, un
/// enlace de fuera) se cae al Inicio; hasta el 2026-08-19 se caía en Comunidad,
/// vinieras de donde vinieras.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget pantalla(String texto, {bool conFlecha = false}) => Scaffold(
    body: Column(
      children: [
        CustomSectionHeader(title: texto, showBackButton: conFlecha),
        Text(texto),
      ],
    ),
  );

  GoRouter router({required void Function(GoRouter r) alArrancar}) {
    final r = GoRouter(
      initialLocation: '/origen',
      routes: [
        GoRoute(path: '/home', builder: (_, _) => pantalla('INICIO')),
        GoRoute(path: '/origen', builder: (_, _) => pantalla('ORIGEN')),
        GoRoute(
          path: '/detalle',
          builder: (_, _) => pantalla('DETALLE', conFlecha: true),
        ),
      ],
    );
    alArrancar(r);
    return r;
  }

  testWidgets('con push, la flecha devuelve a la pantalla de origen', (tester) async {
    late GoRouter r;
    await tester.pumpWidget(
      MaterialApp.router(routerConfig: router(alArrancar: (x) => r = x)),
    );
    await tester.pumpAndSettle();

    r.push('/detalle');
    await tester.pumpAndSettle();
    expect(find.text('DETALLE'), findsWidgets);

    await tester.tap(find.byIcon(Icons.arrow_back_ios));
    await tester.pumpAndSettle();

    expect(find.text('ORIGEN'), findsWidgets);
    expect(find.text('DETALLE'), findsNothing);
  });

  testWidgets('con go no hay nada que desapilar y se cae al Inicio, no a Comunidad', (tester) async {
    late GoRouter r;
    await tester.pumpWidget(
      MaterialApp.router(routerConfig: router(alArrancar: (x) => r = x)),
    );
    await tester.pumpAndSettle();

    r.go('/detalle');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back_ios));
    await tester.pumpAndSettle();

    expect(find.text('INICIO'), findsWidgets);
  });
}
