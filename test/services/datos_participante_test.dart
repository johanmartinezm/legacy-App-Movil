import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:legacy_app/data/config/config_service.dart';
import 'package:legacy_app/data/services/event_service.dart';
import 'package:legacy_app/data/services/payment_service.dart';

/// El formulario de "Datos del Participante" se validaba desde el 2026-08-05 y
/// **se tiraba**: no había ruta que aceptara esos campos. Y el selector de
/// tarjeta o PSE tampoco viajaba. Esto fija que ahora llegan.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await ConfigService.initialize();
  });

  group('inscripción a un evento', () {
    test('el contacto del participante viaja en el cuerpo', () async {
      Map<String, dynamic>? enviado;

      final servicio = EventService(
        client: MockClient((req) async {
          enviado = jsonDecode(req.body) as Map<String, dynamic>;
          return http.Response('{"id":"reg-1"}', 201);
        }),
      );

      await servicio.registerToEvent(
        'ev-1',
        'token',
        participantName: 'Ana Restrepo',
        participantEmail: 'ana@ejemplo.test',
        participantPhone: '+57 300 000 0000',
      );

      expect(enviado?['participant_name'], 'Ana Restrepo');
      expect(enviado?['participant_email'], 'ana@ejemplo.test');
      expect(enviado?['participant_phone'], '+57 300 000 0000');
    });

    test('sin datos no se manda cuerpo', () async {
      String? cuerpo = 'algo';

      final servicio = EventService(
        client: MockClient((req) async {
          cuerpo = req.body;
          return http.Response('{"id":"reg-1"}', 201);
        }),
      );

      await servicio.registerToEvent('ev-1', 'token');

      // Un objeto vacío no aporta nada y el backend solo lee el cuerpo si llega
      // como JSON.
      expect(cuerpo, isEmpty);
    });

    test('los campos en blanco no se envían', () async {
      Map<String, dynamic>? enviado;

      final servicio = EventService(
        client: MockClient((req) async {
          enviado = jsonDecode(req.body) as Map<String, dynamic>;
          return http.Response('{"id":"reg-1"}', 201);
        }),
      );

      await servicio.registerToEvent(
        'ev-1',
        'token',
        participantName: 'Ana',
        participantEmail: '',
        participantPhone: '',
      );

      expect(enviado?.containsKey('participant_name'), isTrue);
      // Vacío significa "usa los del perfil", y para eso es mejor no mandar la
      // clave que mandarla en blanco.
      expect(enviado?.containsKey('participant_email'), isFalse);
      expect(enviado?.containsKey('participant_phone'), isFalse);
    });
  });

  group('intención de pago', () {
    test('el método elegido viaja', () async {
      Map<String, dynamic>? enviado;

      final servicio = PaymentService(
        client: MockClient((req) async {
          enviado = jsonDecode(req.body) as Map<String, dynamic>;
          return http.Response('{"form_url":"https://pasarela"}', 200);
        }),
      );

      await servicio.createPaymentIntent(
        referenceType: 'EVENT',
        referenceId: 'ev-1',
        amount: 250000,
        returnUrl: 'legacyapp://app/payment-callback',
        token: 'token',
        paymentMethod: 'pse',
      );

      expect(enviado?['payment_method'], 'pse');
    });

    test('sin método elegido, la clave no aparece', () async {
      Map<String, dynamic>? enviado;

      final servicio = PaymentService(
        client: MockClient((req) async {
          enviado = jsonDecode(req.body) as Map<String, dynamic>;
          return http.Response('{"form_url":"https://pasarela"}', 200);
        }),
      );

      await servicio.createPaymentIntent(
        referenceType: 'EVENT',
        referenceId: 'ev-1',
        amount: 250000,
        returnUrl: 'legacyapp://app/payment-callback',
        token: 'token',
      );

      expect(enviado?.containsKey('payment_method'), isFalse);
    });
  });
}
