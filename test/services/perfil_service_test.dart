import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:legacy_app/data/config/config_service.dart';
import 'package:legacy_app/data/config/image_helper.dart';
import 'package:legacy_app/data/services/auth_service.dart';

/// Editar perfil (2026-11-10): la foto no se subía nunca y los rechazos del
/// backend llegaban a la pantalla como un «Error al actualizar perfil» sin
/// motivo.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => ConfigService.initialize());

  test('un 400 llega con el motivo del backend', () async {
    final servicio = AuthService(
      client: MockClient((_) async => http.Response(
            jsonEncode({
              'message':
                  'El alias solo puede contener letras y números, sin espacios ni caracteres especiales.'
            }),
            400,
            headers: {'content-type': 'application/json; charset=utf-8'},
          )),
    );

    await expectLater(
      servicio.updateProfile('t', {'alias': 'Samán'}),
      throwsA(isA<PerfilRechazado>().having(
          (e) => e.mensaje, 'mensaje', startsWith('El alias solo puede'))),
    );
  });

  test('un 409 sigue siendo alias_in_use', () async {
    final servicio =
        AuthService(client: MockClient((_) async => http.Response('', 409)));
    await expectLater(
      servicio.updateProfile('t', {'alias': 'ocupado'}),
      throwsA(predicate((e) => e.toString().contains('alias_in_use'))),
    );
  });

  test('la foto se sube como multipart y vuelve como /api/images/<nombre>',
      () async {
    final dir = await Directory.systemTemp.createTemp('perfil');
    final foto = File('${dir.path}/foto.jpg')..writeAsBytesSync([1, 2, 3]);

    http.BaseRequest? recibida;
    final servicio = AuthService(
      client: MockClient((req) async {
        recibida = req;
        return http.Response(jsonEncode({'name': 'abc_foto.jpg'}), 200);
      }),
    );

    final ruta = await servicio.uploadProfileImage('tok', foto.path);

    expect(ruta, '/api/images/abc_foto.jpg');
    expect(recibida!.url.path, '/api/images/upload');
    expect(recibida!.headers['Authorization'], 'Bearer tok');
    expect(recibida!.headers['content-type'], startsWith('multipart/form-data'));
    await dir.delete(recursive: true);
  });

  test('una ruta relativa se completa con la URL del backend', () {
    expect(ImageHelper.resolverUrl('/api/images/x.jpg'),
        endsWith('/api/images/x.jpg'));
    expect(ImageHelper.resolverUrl('/api/images/x.jpg'), startsWith('http'));
    expect(ImageHelper.resolverUrl('https://otra.com/a.png'),
        'https://otra.com/a.png');
  });
}
