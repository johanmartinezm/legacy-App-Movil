import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:legacy_app/data/services/contacto_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('envia asunto y mensaje con el token en la cabecera', () async {
    late http.Request enviada;
    final client = MockClient((request) async {
      enviada = request;
      return http.Response('{"message":"Mensaje enviado con éxito"}', 200);
    });

    await ContactoService(client: client).enviarMensaje(
      token: 'token-de-prueba',
      asunto: 'Duda con un evento',
      mensaje: 'No puedo inscribirme',
    );

    expect(enviada.method, 'POST');
    expect(enviada.url.path, endsWith('/api/contacto'));
    expect(enviada.headers['Authorization'], 'Bearer token-de-prueba');

    final cuerpo = json.decode(enviada.body) as Map<String, dynamic>;
    expect(cuerpo['asunto'], 'Duda con un evento');
    expect(cuerpo['mensaje'], 'No puedo inscribirme');
    // El remitente lo pone el backend desde el perfil autenticado: mandarlo
    // desde aquí permitiría escribir en nombre de otro.
    expect(cuerpo.containsKey('email'), isFalse);
    expect(cuerpo.containsKey('nombre'), isFalse);
  });

  test('un 400 con texto plano se convierte en un mensaje legible', () async {
    // El backend responde con http.Error, que es texto plano y no JSON.
    // Hacerle json.decode a ciegas daría un FormatException en vez del motivo.
    final client = MockClient((request) async {
      return http.Response('el mensaje no puede estar vacío\n', 400);
    });

    expect(
      () => ContactoService(client: client).enviarMensaje(
        token: 't',
        asunto: 'Asunto',
        mensaje: '',
      ),
      throwsA(predicate((e) => e.toString().contains('el mensaje no puede estar vacío'))),
    );
  });

  test('un 500 sin cuerpo deja un mensaje por defecto', () async {
    final client = MockClient((request) async => http.Response('', 500));

    expect(
      () => ContactoService(client: client).enviarMensaje(
        token: 't',
        asunto: 'Asunto',
        mensaje: 'Hola',
      ),
      throwsA(predicate((e) => e.toString().contains('No se pudo enviar el mensaje'))),
    );
  });
}
