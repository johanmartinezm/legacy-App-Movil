import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:legacy_app/domain/utils/volver_atras.dart';

/// Router mínimo con dos pantallas: una raíz y otra que se puede apilar encima
/// o abrir directa, que son las dos puertas que hay que cubrir.
GoRouter _router(String inicial, String destino) => GoRouter(
      initialLocation: inicial,
      routes: [
        GoRoute(
          path: '/raiz',
          builder: (context, state) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => context.push('/dentro'),
                child: const Text('entrar'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/dentro',
          builder: (context, state) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => volverAtras(context, destino: destino),
                child: const Text('volver'),
              ),
            ),
          ),
        ),
      ],
    );

void main() {
  testWidgets('con pila, deshace el último paso', (tester) async {
    await tester.pumpWidget(
      MaterialApp.router(routerConfig: _router('/raiz', '/raiz')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('entrar'));
    await tester.pumpAndSettle();
    expect(find.text('volver'), findsOneWidget);

    await tester.tap(find.text('volver'));
    await tester.pumpAndSettle();

    expect(find.text('entrar'), findsOneWidget);
  });

  testWidgets('sin pila, va al destino en vez de quedarse quieta',
      (tester) async {
    // Es el caso del enlace profundo y el de una notificación: la pantalla es
    // la primera de la pila, así que `pop()` a secas no haría nada.
    await tester.pumpWidget(
      MaterialApp.router(routerConfig: _router('/dentro', '/raiz')),
    );
    await tester.pumpAndSettle();
    expect(find.text('volver'), findsOneWidget);

    await tester.tap(find.text('volver'));
    await tester.pumpAndSettle();

    expect(find.text('entrar'), findsOneWidget);
  });
}
