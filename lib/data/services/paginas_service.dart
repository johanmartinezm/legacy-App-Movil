import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_constants.dart';
import '../config/config_service.dart';
import '../../domain/models/pagina_informativa_model.dart';

/// Excepción con un mensaje ya escrito para mostrar en pantalla.
class PaginaNoDisponible implements Exception {
  final String mensaje;
  const PaginaNoDisponible(this.mensaje);

  @override
  String toString() => mensaje;
}

/// Lee las páginas de información que edita el panel.
///
/// No necesita sesión: la ruta del backend es pública, igual que los banners.
class PaginasService {
  final String _baseUrl = ConfigService.apiBaseUrl;
  final http.Client _client;

  /// El cliente se inyecta para poder sustituirlo en las pruebas, igual que en
  /// `ContactoService`.
  PaginasService({http.Client? client}) : _client = client ?? http.Client();

  Future<PaginaInformativa> obtener(String slug) async {
    final url = Uri.parse('$_baseUrl${ApiConstants.paginaEndpoint(slug)}');

    final response = await _client.get(url);

    if (response.statusCode == 200) {
      // El backend responde en UTF-8 y esta pantalla es casi toda texto: sin
      // decodificarlo a mano, las tildes salen partidas.
      final data = json.decode(utf8.decode(response.bodyBytes));
      return PaginaInformativa.fromJson(data as Map<String, dynamic>);
    }

    // 404 es el caso normal cuando el panel despublica la página, no un fallo.
    if (response.statusCode == 404) {
      throw const PaginaNoDisponible(
        'Esta sección no está disponible por el momento.',
      );
    }

    throw const PaginaNoDisponible(
      'No pudimos cargar el contenido. Revisa tu conexión e inténtalo de nuevo.',
    );
  }
}
