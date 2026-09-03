import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:legacy_app/data/services/paginas_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('pide la pagina por su slug y la arma', () async {
    late http.Request enviada;
    final client = MockClient((request) async {
      enviada = request;
      // Response.bytes y no Response: es lo que ejercita el utf8.decode del
      // servicio, que es donde se partian las tildes.
      return http.Response.bytes(
        utf8.encode(json.encode({
          'slug': 'legacy-board',
          'titulo': 'Legacy Board',
          'subtitulo': 'Gobierno corporativo',
          'imagen_url': '',
          'cuerpo': 'Primer párrafo.\n\nSegundo párrafo.',
          'publicada': true,
          'actualizada_en': '2026-09-02T10:00:00Z',
        })),
        200,
      );
    });

    final pagina = await PaginasService(client: client).obtener('legacy-board');

    expect(enviada.method, 'GET');
    expect(enviada.url.path, endsWith('/api/paginas/legacy-board'));
    // La ruta es publica: pedir sesion para leer un texto informativo dejaria
    // la pantalla en blanco a quien tenga el token caducado.
    expect(enviada.headers.containsKey('Authorization'), isFalse);

    expect(pagina.titulo, 'Legacy Board');
    expect(pagina.parrafos, ['Primer párrafo.', 'Segundo párrafo.']);
  });

  test('las tildes sobreviven al decodificar', () async {
    final client = MockClient((request) async => http.Response.bytes(
          utf8.encode(json.encode({
            'slug': 'legacy-board',
            'titulo': 'Participación',
            'cuerpo': 'Órganos de gobierno.',
          })),
          200,
        ));

    final pagina = await PaginasService(client: client).obtener('legacy-board');

    expect(pagina.titulo, 'Participación');
    expect(pagina.cuerpo, 'Órganos de gobierno.');
  });

  test('un 404 dice que la seccion no esta disponible, no que fallo la red',
      () async {
    // Es lo que responde el backend cuando el panel despublica la pagina: no
    // es un error de conexion y no debe invitar a reintentar sin parar.
    final client = MockClient(
      (request) async => http.Response('la página no existe o no está publicada', 404),
    );

    expect(
      () => PaginasService(client: client).obtener('legacy-board'),
      throwsA(predicate(
        (e) => e is PaginaNoDisponible && e.mensaje.contains('no está disponible'),
      )),
    );
  });

  test('un 500 pide revisar la conexion', () async {
    final client = MockClient((request) async => http.Response('', 500));

    expect(
      () => PaginasService(client: client).obtener('legacy-board'),
      throwsA(predicate(
        (e) => e is PaginaNoDisponible && e.mensaje.contains('conexión'),
      )),
    );
  });
}
