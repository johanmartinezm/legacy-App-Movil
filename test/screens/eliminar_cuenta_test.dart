import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_app/domain/providers/auth_provider.dart';
import 'package:legacy_app/presentation/widgets/perfil/eliminar_cuenta_dialog.dart';
import 'package:provider/provider.dart';

/// Eliminar la cuenta desde la app es requisito de App Store y de Google Play.
/// Lo que se prueba aquí es la barrera: que no se pueda disparar por accidente
/// y que un fallo del servidor no deje al usuario creyendo que se borró.

class _AuthFake extends AuthProvider {
  _AuthFake({this.fallo});

  final String? fallo;
  int llamadas = 0;

  @override
  Future<void> deleteAccount() async {
    llamadas++;
    if (fallo != null) throw Exception(fallo);
  }
}

Future<void> _montar(WidgetTester tester, AuthProvider auth) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<AuthProvider>.value(
      value: auth,
      child: const MaterialApp(
        home: Scaffold(body: EliminarCuentaDialog()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('el boton nace deshabilitado: no se borra de un toque', (tester) async {
    final auth = _AuthFake();
    await _montar(tester, auth);

    final boton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(boton.onPressed, isNull, reason: 'sin escribir ELIMINAR no debe poder pulsarse');
    expect(auth.llamadas, 0);
  });

  testWidgets('una palabra que no es ELIMINAR no habilita el boton', (tester) async {
    await _montar(tester, _AuthFake());

    await tester.enterText(find.byType(TextField), 'eliminar mi cuenta');
    await tester.pump();

    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
  });

  testWidgets('ELIMINAR habilita el boton y borra la cuenta', (tester) async {
    final auth = _AuthFake();
    await _montar(tester, auth);

    await tester.enterText(find.byType(TextField), 'ELIMINAR');
    await tester.pump();

    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNotNull);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(auth.llamadas, 1);
  });

  testWidgets('se acepta en minusculas: la palabra, no el teclado', (tester) async {
    final auth = _AuthFake();
    await _montar(tester, auth);

    await tester.enterText(find.byType(TextField), 'eliminar');
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(auth.llamadas, 1);
  });

  testWidgets('si el servidor falla, se avisa y NO se cierra el dialogo', (tester) async {
    // Lo peor seria cerrar el dialogo tras un fallo: el usuario creeria que su
    // cuenta se borro cuando sigue existiendo.
    final auth = _AuthFake(fallo: 'No se pudo eliminar la cuenta (500).');
    await _montar(tester, auth);

    await tester.enterText(find.byType(TextField), 'ELIMINAR');
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.textContaining('No se pudo eliminar la cuenta'), findsOneWidget);
    expect(find.byType(EliminarCuentaDialog), findsOneWidget);
  });

  testWidgets('se avisa de que las inscripciones y mensajes se conservan', (tester) async {
    // Prometer un borrado total y conservar registros seria enganar.
    await _montar(tester, _AuthFake());

    expect(find.textContaining('se conservan sin tu nombre'), findsOneWidget);
  });
}
