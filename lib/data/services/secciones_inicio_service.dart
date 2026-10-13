import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_constants.dart';
import '../config/config_service.dart';

/// Lo que el panel cambia de una tarjeta del Inicio. Cada campo es `null`
/// cuando el panel lo dejó vacío: la tarjeta usa entonces lo de siempre (su
/// icono, y el título y el texto escritos en la app).
class SeccionInicio {
  final String? imagenUrl;
  final String? titulo;
  final String? texto;

  const SeccionInicio({this.imagenUrl, this.titulo, this.texto});
}

/// Imagen, título y texto de las tarjetas del Inicio, que se cambian desde el
/// panel.
///
/// Devuelve `slug → SeccionInicio` solo de las que tienen algo cambiado.
/// **Nunca falla**: el Inicio es la primera pantalla de la app y no puede
/// quedarse en blanco porque el backend no responda; sin datos, cada tarjeta se
/// pinta como siempre.
class SeccionesInicioService {
  final String _baseUrl = ConfigService.apiBaseUrl;
  final http.Client _client;

  /// El cliente se inyecta para poder sustituirlo en las pruebas.
  SeccionesInicioService({http.Client? client})
      : _client = client ?? http.Client();

  Future<Map<String, SeccionInicio>> secciones() async {
    try {
      final url = Uri.parse('$_baseUrl${ApiConstants.seccionesInicioEndpoint}');
      final response = await _client.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return const {};

      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data is! List) return const {};

      final secciones = <String, SeccionInicio>{};
      for (final s in data) {
        if (s is! Map) continue;
        final slug = s['slug'];
        if (slug is! String) continue;
        // Un backend anterior no manda titulo ni texto: quedan en null.
        final seccion = SeccionInicio(
          imagenUrl: _noVacio(s['imagen_url']),
          titulo: _noVacio(s['titulo']),
          texto: _noVacio(s['texto']),
        );
        if (seccion.imagenUrl != null ||
            seccion.titulo != null ||
            seccion.texto != null) {
          secciones[slug] = seccion;
        }
      }
      return secciones;
    } catch (_) {
      return const {};
    }
  }

  static String? _noVacio(Object? valor) {
    if (valor is! String) return null;
    final limpio = valor.trim();
    return limpio.isEmpty ? null : limpio;
  }
}
