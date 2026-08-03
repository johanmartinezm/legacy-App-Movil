import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config_service.dart';

class BoardService {
  final String _baseUrl = ConfigService.apiBaseUrl;

  Future<void> sendContactMessage({
    required String token,
    required String contactId,
    required String message,
  }) async {
    final url = Uri.parse('$_baseUrl/api/board/contact');
    
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'contact_id': contactId,
        'message': message,
      }),
    );

    if (response.statusCode != 200) {
      final data = json.decode(response.body);
      throw Exception(data['message'] ?? 'Error al enviar el mensaje');
    }
  }
}
