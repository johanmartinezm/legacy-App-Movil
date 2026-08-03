import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ConfigService {
  static Map<String, dynamic> _config = {};

  static Future<void> initialize() async {
    try {
      // Intentamos cargar el archivo con un timeout muy corto para no bloquear la app
      final String response = await rootBundle
          .loadString('assets/config/config.json')
          .timeout(const Duration(milliseconds: 500));
      _config = json.decode(response);
      debugPrint('✅ Configuración cargada desde JSON');
    } catch (e) {
      // Si falla, NO lanzamos error, usamos un mapa vacío y los getters darán los defaults
      debugPrint(
        '⚠️ No se pudo cargar config.json, usando valores por defecto: $e',
      );
      _config = {};
    }
  }

  static String get apiBaseUrl {
    // Si no hay config, devolvemos los valores que tenías originalmente
    if (kIsWeb) {
      return _config['api_url_web'] ?? 'http://localhost:8080';
    }

    // Usamos defaultTargetPlatform que es más seguro para Flutter
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _config['api_url_android'] ?? 'http://10.0.2.2:8080';
    }

    return _config['api_url_ios'] ?? 'http://localhost:8080';
  }

  static String get graphqlBaseUrl =>
      _config['graphql_url'] ?? 'https://lso.school/graphql';

  static String get contentGraphqlUrl =>
      _config['content_graphql_url'] ?? 'https://legacynetworkco.com/graphql';

  static String get environment => _config['environment'] ?? 'development';
}
