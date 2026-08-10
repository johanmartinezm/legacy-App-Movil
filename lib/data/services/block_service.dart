import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_constants.dart';
import '../models/blocked_user_model.dart';

/// Bloquear y reportar a otras personas.
///
/// Ninguna de estas llamadas envía quién actúa: el servidor lo toma del token.
/// Mandarlo permitiría bloquear o reportar en nombre de otra persona.
class BlockService {
  final String token;

  BlockService(this.token);

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  Future<void> blockUser(String userId) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.blockUserEndpoint(userId)}'),
      headers: _headers,
    );
    // 204 al bloquear; 200 por si el servidor cambiara a devolver cuerpo.
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(_mensajeDeError(response.body, 'No se pudo bloquear'));
    }
  }

  Future<void> unblockUser(String userId) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.blockUserEndpoint(userId)}'),
      headers: _headers,
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(_mensajeDeError(response.body, 'No se pudo desbloquear'));
    }
  }

  Future<List<BlockedUser>> listBlocked() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.blocksEndpoint}'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception(
        _mensajeDeError(response.body, 'No se pudo cargar la lista'),
      );
    }
    final decoded = json.decode(response.body);
    if (decoded == null) return [];
    return (decoded as List)
        .map((e) => BlockedUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Reporta a una persona. [messageId] es opcional: se envía cuando el reporte
  /// sale de un mensaje concreto del chat, y se omite si viene de un perfil.
  Future<void> reportUser(
    String userId,
    String reason, {
    String? messageId,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.reportUserEndpoint(userId)}'),
      headers: _headers,
      body: json.encode({
        'reason': reason,
        if (messageId != null) 'message_id': messageId,
      }),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
        _mensajeDeError(response.body, 'No se pudo enviar el reporte'),
      );
    }
  }

  /// El backend responde {"message": "..."} en los errores. Si el cuerpo no es
  /// el esperado se usa el texto por defecto: mostrar JSON en crudo no le dice
  /// nada a quien está usando la app.
  String _mensajeDeError(String body, String porDefecto) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map && decoded['message'] is String) {
        return decoded['message'] as String;
      }
    } catch (_) {}
    return porDefecto;
  }
}
