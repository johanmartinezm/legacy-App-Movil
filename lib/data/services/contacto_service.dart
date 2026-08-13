import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config_service.dart';

/// Envia el mensaje de la pantalla "Contactenos" al buzon de soporte.
///
/// El remitente no se manda: el backend lo saca del perfil de quien esta
/// autenticado, para que nadie pueda escribir haciendose pasar por otro.
class ContactoService {
  final String _baseUrl = ConfigService.apiBaseUrl;
  final http.Client _client;

  /// El cliente se inyecta para poder sustituirlo en las pruebas, igual que en
  /// `EventService`.
  ContactoService({http.Client? client}) : _client = client ?? http.Client();

  Future<void> enviarMensaje({
    required String token,
    required String asunto,
    required String mensaje,
  }) async {
    final url = Uri.parse('$_baseUrl/api/contacto');

    final response = await _client.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'asunto': asunto,
        'mensaje': mensaje,
      }),
    );

    if (response.statusCode == 200) return;

    // El backend responde 400 con texto plano cuando rechaza el contenido
    // (mensaje vacio o demasiado largo), y JSON en otros casos. Intentar
    // json.decode a ciegas convertiria un error explicable en un FormatException.
    String detalle = 'No se pudo enviar el mensaje';
    try {
      final data = json.decode(response.body);
      if (data is Map && data['message'] != null) {
        detalle = data['message'].toString();
      }
    } catch (_) {
      final cuerpo = response.body.trim();
      if (cuerpo.isNotEmpty) detalle = cuerpo;
    }
    throw Exception(detalle);
  }
}
