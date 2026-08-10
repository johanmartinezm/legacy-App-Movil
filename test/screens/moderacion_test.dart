import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_app/domain/providers/block_provider.dart';
import 'package:legacy_app/presentation/widgets/moderacion/reportar_usuario_dialog.dart';
import 'package:provider/provider.dart';

/// Bloquear y reportar son requisito de la directriz 1.2 de Apple para toda app
/// con chat o contenido publicado por sus usuarios. Lo que se prueba aquí es que
/// el reporte no se pueda enviar vacío y que un fallo del servidor no deje a
/// nadie creyendo que denunció a quien le acosa.

class _BlockFake extends BlockProvider {
  _BlockFake({this.falla = false});

  final bool falla;
  int llamadas = 0;
  String? ultimoMotivo;
  String? ultimoUsuario;

  @override
  Future<bool> reportUser(String userId, String reason, {String? messageId}) async {
    llamadas++;
    ultimoUsuario = userId;
    ultimoMotivo = reason;
    if (falla) return false;
    return true;
  }

  @override
  String? get error => falla ? 'No se pudo enviar el reporte' : null;
}

Future<void> _montar(WidgetTester tester, BlockProvider provider) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<BlockProvider>.value(
      value: provider,
      child: const MaterialApp(
        home: Scaffold(
          body: ReportarUsuarioDialog(userId: 'u-1', userName: 'Ana'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('el botón de enviar nace deshabilitado sin motivo', (tester) async {
    final fake = _BlockFake();
    await _montar(tester, fake);

    final boton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(boton.onPressed, isNull,
        reason: 'sin motivo no debe poder enviarse el reporte');
  });

  testWidgets('elegir un motivo habilita el envío', (tester) async {
    final fake = _BlockFake();
    await _montar(tester, fake);

    await tester.tap(find.text('Acoso o amenazas'));
    await tester.pumpAndSettle();

    final boton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(boton.onPressed, isNotNull);
  });

  testWidgets('el motivo elegido llega tal cual al provider', (tester) async {
    final fake = _BlockFake();
    await _montar(tester, fake);

    await tester.tap(find.text('Spam o publicidad'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar reporte'));
    await tester.pumpAndSettle();

    expect(fake.llamadas, 1);
    expect(fake.ultimoMotivo, 'Spam o publicidad');
    expect(fake.ultimoUsuario, 'u-1');
  });

  testWidgets('"Otro motivo" en blanco no permite enviar', (tester) async {
    // "Otro motivo" viene seleccionado de inicio con el campo vacío: si el botón
    // se habilitara, se enviaría un reporte sin contenido que nadie podría
    // revisar.
    final fake = _BlockFake();
    await _montar(tester, fake);

    await tester.tap(find.text('Otro motivo'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pumpAndSettle();

    final boton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(boton.onPressed, isNull);
    expect(fake.llamadas, 0);
  });

  testWidgets('si el envío falla, el diálogo NO se cierra y muestra el error',
      (tester) async {
    // Lo peor sería que alguien creyera haber reportado a quien le acosa cuando
    // el reporte no llegó.
    final fake = _BlockFake(falla: true);
    await _montar(tester, fake);

    await tester.tap(find.text('Acoso o amenazas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar reporte'));
    await tester.pumpAndSettle();

    expect(find.byType(ReportarUsuarioDialog), findsOneWidget,
        reason: 'el diálogo debe seguir abierto tras un fallo');
    expect(find.text('No se pudo enviar el reporte'), findsOneWidget);
  });

  testWidgets('avisa de que reportar no bloquea', (tester) async {
    // Son dos acciones distintas y confundirlas dejaría a alguien esperando que
    // el acoso pare solo por haber reportado.
    final fake = _BlockFake();
    await _montar(tester, fake);

    expect(
      find.textContaining('Reportar no bloquea'),
      findsOneWidget,
    );
  });
}
