import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config_service.dart';

class AsesoriaService {
  final String _baseUrl = ConfigService.apiBaseUrl;

  Future<void> requestAsesoria({
    required String token,
    required String category,
    required String message,
  }) async {
    final url = Uri.parse('$_baseUrl/api/asesoria/request');
    
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'category': category,
        'message': message,
      }),
    );

    if (response.statusCode != 200) {
      final data = json.decode(response.body);
      throw Exception(data['message'] ?? 'Error al solicitar asesoría');
    }
  }
}
