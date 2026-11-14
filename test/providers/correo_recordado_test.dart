import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:legacy_app/data/config/config_service.dart';
import 'package:legacy_app/data/services/auth_service.dart';
import 'package:legacy_app/domain/providers/auth_provider.dart';

/// Con «Recordarme» marcado, el correo tiene que seguir en el formulario de
/// entrada justo cuando hace falta volver a entrar: al cerrar sesión y cuando
/// la sesión guardada caduca. Hasta el 2026-11-13 se borraba en los dos casos.
String jwtCon(Map<String, dynamic> payload) {
  String parte(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${parte({'alg': 'HS256', 'typ': 'JWT'})}.${parte(payload)}.firma';
}

int segundosDesde(Duration d) =>
    DateTime.now().add(d).millisecondsSinceEpoch ~/ 1000;

/// Responde al login y a /me como lo haría el backend.
AuthService servicioQueAcepta() => AuthService(
  client: MockClient((req) async {
    if (req.url.path.endsWith('/me')) {
      return http.Response(
        jsonEncode({
          'id': 'user-1',
          'email': 'quien@sea.test',
          'first_name': 'Quien',
          'customer_status': 'active',
        }),
        200,
      );
    }
    final token = jwtCon({
      'sub': 'user-1',
      'exp': segundosDesde(const Duration(days: 30)),
    });
    return http.Response(jsonEncode({'token': token}), 200);
  }),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await ConfigService.initialize();
  });

  const storage = FlutterSecureStorage();

  test('Cerrar sesión borra la sesión pero conserva el correo', () async {
    FlutterSecureStorage.setMockInitialValues({
      'auth_token': jwtCon({
        'sub': 'user-1',
        'exp': segundosDesde(const Duration(days: 10)),
      }),
      'user_email': 'quien@sea.test',
      'user_id': 'user-1',
      'user_alias': 'alias',
    });
    final auth = AuthProvider(authService: servicioQueAcepta());

    await auth.logout();

    expect(await storage.read(key: 'auth_token'), isNull);
    expect(await storage.read(key: 'user_id'), isNull);
    expect(await storage.read(key: 'user_alias'), isNull);
    expect(await auth.getSavedEmail(), 'quien@sea.test');
  });

  test('Una sesión caducada se limpia pero conserva el correo', () async {
    FlutterSecureStorage.setMockInitialValues({
      'auth_token': jwtCon({
        'sub': 'user-1',
        'exp': segundosDesde(const Duration(hours: -1)),
      }),
      'user_email': 'quien@sea.test',
    });
    final auth = AuthProvider(authService: servicioQueAcepta());

    await auth.checkLoginStatus();

    expect(auth.isAuthenticated, isFalse);
    expect(await storage.read(key: 'auth_token'), isNull);
    expect(await auth.getSavedEmail(), 'quien@sea.test');
  });

  test('Entrar sin «Recordarme» olvida el correo guardado', () async {
    FlutterSecureStorage.setMockInitialValues({'user_email': 'otro@sea.test'});
    final auth = AuthProvider(authService: servicioQueAcepta());

    await pumpEventQueue(); // que termine el checkLoginStatus del constructor
    final ok = await auth.login('quien@sea.test', 'LaBuena123');
    // Lo que hace el Inicio nada más entrar.
    await auth.fetchProfile();

    expect(ok, isTrue);
    expect(await auth.getSavedEmail(), isNull);
    expect(await storage.read(key: 'auth_token'), isNull);
    expect(await storage.read(key: 'user_id'), isNull);
  });

  test('Entrar con «Recordarme» guarda el correo y la sesión', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final auth = AuthProvider(authService: servicioQueAcepta());

    final ok = await auth.login(
      'quien@sea.test',
      'LaBuena123',
      rememberMe: true,
    );

    expect(ok, isTrue);
    expect(await auth.getSavedEmail(), 'quien@sea.test');
    expect(await storage.read(key: 'auth_token'), isNotNull);
  });
}
