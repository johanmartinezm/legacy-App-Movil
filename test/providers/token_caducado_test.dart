import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_app/domain/providers/auth_provider.dart';

/// El token del backend dura 24 horas (`auth_service.go:54`) y no hay refresh
/// token. Sin detectar la caducidad, "Recordarme" metía al usuario en la app con
/// un token muerto y todas las llamadas fallaban con 401.
String jwtCon(Map<String, dynamic> payload) {
  String parte(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${parte({'alg': 'HS256', 'typ': 'JWT'})}.${parte(payload)}.firma';
}

int segundosDesde(Duration d) =>
    DateTime.now().add(d).millisecondsSinceEpoch ~/ 1000;

void main() {
  group('AuthProvider.tokenCaducado', () {
    test('Un token vigente no está caducado', () {
      final token = jwtCon({
        'sub': 'user-1',
        'exp': segundosDesde(const Duration(hours: 12)),
      });
      expect(AuthProvider.tokenCaducado(token), isFalse);
    });

    test('Un token vencido sí lo está', () {
      // El caso real: se marcó "Recordarme" y se vuelve al día siguiente.
      final token = jwtCon({
        'sub': 'user-1',
        'exp': segundosDesde(const Duration(hours: -1)),
      });
      expect(AuthProvider.tokenCaducado(token), isTrue);
    });

    test('Justo en el límite de las 24 horas', () {
      final vencido = jwtCon({
        'exp': segundosDesde(const Duration(hours: 24, seconds: -1)),
      });
      expect(AuthProvider.tokenCaducado(vencido), isFalse,
          reason: 'un segundo antes todavía sirve');

      final pasado = jwtCon({
        'exp': segundosDesde(const Duration(seconds: -1)),
      });
      expect(AuthProvider.tokenCaducado(pasado), isTrue);
    });

    test('Nulo o vacío cuenta como caducado', () {
      expect(AuthProvider.tokenCaducado(null), isTrue);
      expect(AuthProvider.tokenCaducado(''), isTrue);
    });

    test('Un token con formato inválido cuenta como caducado', () {
      expect(AuthProvider.tokenCaducado('esto-no-es-un-jwt'), isTrue);
      expect(AuthProvider.tokenCaducado('a.b'), isTrue);
      expect(AuthProvider.tokenCaducado('a.no-es-base64-valido!!.c'), isTrue);
    });

    test('Sin claim exp se deja pasar: lo juzga el servidor', () {
      // Mejor una llamada que devuelva 401 que cerrar la sesión de alguien cuyo
      // token es perfectamente válido pero sin fecha de caducidad.
      final token = jwtCon({'sub': 'user-1'});
      expect(AuthProvider.tokenCaducado(token), isFalse);
    });
  });
}
