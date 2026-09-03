import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:legacy_app/data/config/config_service.dart';
import 'package:legacy_app/data/services/auth_service.dart';
import 'package:legacy_app/domain/providers/auth_provider.dart';
import 'package:legacy_app/presentation/screens/profile/cambiar_contrasena_screen.dart';
import 'package:provider/provider.dart';

/// Las cuentas que entran por una carga masiva traen como contraseña su número
/// de documento, que no es un secreto: viene en el archivo importado. Por eso
/// el backend las marca y la app las trae aquí sin salida.
/// Ver reports/20260826_plan_carga_masiva.md §2.5.
///
/// `AuthProvider` real toca `flutter_secure_storage`, que no existe en las
/// pruebas: se neutraliza lo que esta pantalla le pide.
class _AuthFake extends AuthProvider {
  bool _obligado = true;
  int levantadas = 0;

  @override
  String? get token => 'token-de-prueba';

  @override
  bool get debeCambiarContrasena => _obligado;

  @override
  void marcarContrasenaCambiada() {
    _obligado = false;
    levantadas++;
  }

  @override
  Future<void> fetchProfile() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await ConfigService.initialize();
  });

  /// Devuelve el servicio y la lista de cuerpos que recibió el endpoint de
  /// cambio, para poder comprobar qué se mandó.
  (AuthService, List<Map<String, dynamic>>) servicio({int estado = 200}) {
    final enviados = <Map<String, dynamic>>[];
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/api/me/change-password')) {
        enviados.add(json.decode(request.body) as Map<String, dynamic>);
        if (estado != 200) {
          return http.Response(
            json.encode({'message': 'La contraseña actual no es correcta'}),
            estado,
          );
        }
        return http.Response('{}', 200);
      }
      return http.Response('{}', 200);
    });
    return (AuthService(client: client), enviados);
  }

  Future<_AuthFake> montar(WidgetTester tester, AuthService s) async {
    final fake = _AuthFake();
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: fake,
        child: MaterialApp(home: CambiarContrasenaScreen(servicio: s)),
      ),
    );
    await tester.pump();
    return fake;
  }

  testWidgets('no ofrece ninguna salida', (tester) async {
    final (s, _) = servicio();
    await montar(tester, s);

    expect(find.text('Cambia tu contraseña'), findsOneWidget);
    // Ni flecha ni cancelar: es lo que la distingue del diálogo voluntario de
    // editar perfil.
    expect(find.byType(BackButton), findsNothing);
    expect(find.text('Cancelar'), findsNothing);
    expect(find.text('Es tu número de documento'), findsOneWidget);
  });

  testWidgets('rechaza repetir la actual y una confirmación distinta',
      (tester) async {
    final (s, enviados) = servicio();
    final fake = await montar(tester, s);

    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), '10203040');
    await tester.enterText(campos.at(1), '10203040');
    await tester.enterText(campos.at(2), 'otraCosa1');
    await tester.tap(find.text('Guardar y continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Tiene que ser distinta de la actual'), findsOneWidget);
    expect(find.text('Las dos contraseñas no coinciden'), findsOneWidget);
    expect(enviados, isEmpty);
    expect(fake.debeCambiarContrasena, isTrue);
  });

  testWidgets('exige el mínimo de seis caracteres', (tester) async {
    // El mismo que aplica el backend en domain.ValidarContrasena.
    final (s, enviados) = servicio();
    await montar(tester, s);

    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), '10203040');
    await tester.enterText(campos.at(1), 'corta');
    await tester.enterText(campos.at(2), 'corta');
    await tester.tap(find.text('Guardar y continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Al menos 6 caracteres'), findsOneWidget);
    expect(enviados, isEmpty);
  });

  testWidgets('al guardar manda las dos contraseñas y levanta la obligación',
      (tester) async {
    final (s, enviados) = servicio();
    final fake = await montar(tester, s);

    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), '10203040');
    await tester.enterText(campos.at(1), 'miClaveNueva1');
    await tester.enterText(campos.at(2), 'miClaveNueva1');
    await tester.tap(find.text('Guardar y continuar'));
    await tester.pumpAndSettle();

    expect(enviados.single['old_password'], '10203040');
    expect(enviados.single['new_password'], 'miClaveNueva1');
    // Se levanta aquí y no releyendo el perfil: si la red fallara justo
    // después, quedaría encerrada con la contraseña ya cambiada.
    expect(fake.levantadas, 1);
    expect(fake.debeCambiarContrasena, isFalse);
  });

  testWidgets('si el servidor rechaza, sigue obligada y lo explica',
      (tester) async {
    final (s, _) = servicio(estado: 400);
    final fake = await montar(tester, s);

    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'equivocada');
    await tester.enterText(campos.at(1), 'miClaveNueva1');
    await tester.enterText(campos.at(2), 'miClaveNueva1');
    await tester.tap(find.text('Guardar y continuar'));
    await tester.pumpAndSettle();

    expect(find.text('La contraseña actual no es correcta'), findsOneWidget);
    expect(fake.debeCambiarContrasena, isTrue);
  });
}
