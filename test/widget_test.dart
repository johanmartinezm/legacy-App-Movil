// Smoke test de `MyApp`: comprueba el cableado minimo de la raiz de la app
// —que el `GoRouter` recibido es el que pinta, y que el tema propio queda
// aplicado—. Sustituye a la plantilla de contador de `flutter create`, que
// buscaba un `0` y un boton `+` que esta app nunca tuvo.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:legacy_app/main.dart';
import 'package:legacy_app/config/theme/app_theme.dart';

void main() {
  testWidgets('MyApp pinta la ruta inicial del router que recibe', (
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Text('pantalla inicial')),
        ),
        GoRoute(
          path: '/otra',
          builder: (context, state) => const Scaffold(body: Text('otra')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MyApp(router: router));
    await tester.pumpAndSettle();

    expect(find.text('pantalla inicial'), findsOneWidget);
    expect(find.text('otra'), findsNothing);
  });

  testWidgets('MyApp navega cuando el router cambia de ruta', (
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Text('pantalla inicial')),
        ),
        GoRoute(
          path: '/otra',
          builder: (context, state) => const Scaffold(body: Text('otra')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MyApp(router: router));
    await tester.pumpAndSettle();

    router.go('/otra');
    await tester.pumpAndSettle();

    expect(find.text('otra'), findsOneWidget);
    expect(find.text('pantalla inicial'), findsNothing);
  });

  testWidgets('MyApp aplica el tema de la app y oculta la cinta de debug', (
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('inicio')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MyApp(router: router));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.debugShowCheckedModeBanner, isFalse);
    expect(app.theme?.colorScheme.primary,
        AppTheme.lightTheme.colorScheme.primary);
  });
}
