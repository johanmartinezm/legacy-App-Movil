import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_constants.dart';
import '../config/config_service.dart';

/// Imágenes de las tarjetas del Inicio, que se cambian desde el panel.
///
/// Devuelve `slug → URL` solo de las que tienen imagen. **Nunca falla**: el
/// Inicio es la primera pantalla de la app y no puede quedarse en blanco porque
/// el backend no responda; sin imágenes, cada tarjeta se pinta con su icono.
class SeccionesInicioService {
  final String _baseUrl = ConfigService.apiBaseUrl;
  final http.Client _client;

  /// El cliente se inyecta para poder sustituirlo en las pruebas.
  SeccionesInicioService({http.Client? client})
      : _client = client ?? http.Client();

  Future<Map<String, String>> imagenes() async {
    try {
      final url = Uri.parse('$_baseUrl${ApiConstants.seccionesInicioEndpoint}');
      final response = await _client.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return const {};

      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data is! List) return const {};

      final imagenes = <String, String>{};
      for (final s in data) {
        if (s is! Map) continue;
        final slug = s['slug'];
        final url = (s['imagen_url'] as String?)?.trim() ?? '';
        if (slug is String && url.isNotEmpty) imagenes[slug] = url;
      }
      return imagenes;
    } catch (_) {
      return const {};
    }
  }
}
