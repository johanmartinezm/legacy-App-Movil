import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:legacy_app/data/config/config_service.dart';
import 'package:legacy_app/data/services/forum_service.dart';
import 'package:legacy_app/domain/providers/auth_provider.dart';
import 'package:legacy_app/domain/providers/forum_provider.dart';

/// Los foros son solo para usuarios Legacy+ desde el 2026-10-13: el 403 del
/// backend se distingue de un error y llega con su mensaje.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await ConfigService.initialize();
  });

  ForumProvider proveedor(http.Response respuesta) => ForumProvider(
        _AuthConToken(),
        forumService: ForumService(client: MockClient((_) async => respuesta)),
      );

  test('403: soloPlus con el mensaje del backend', () async {
    final p = proveedor(http.Response('Esta sección es para usuarios Legacy+.', 403));
    await p.loadForums();
    expect(p.soloPlus, isTrue);
    expect(p.error, 'Esta sección es para usuarios Legacy+.');
  });

  test('500: error normal, no soloPlus', () async {
    final p = proveedor(http.Response('boom', 500));
    await p.loadForums();
    expect(p.soloPlus, isFalse);
    expect(p.error, isNotNull);
  });

  test('200: carga los foros', () async {
    final p = proveedor(http.Response('[]', 200));
    await p.loadForums();
    expect(p.soloPlus, isFalse);
    expect(p.error, isNull);
  });
}

class _AuthConToken extends AuthProvider {
  @override
  String? get token => 'token-de-prueba';
}
