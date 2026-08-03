import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:legacy_app/data/config/config_service.dart';

class PaymentService {
  final http.Client _client;

  PaymentService({http.Client? client}) : _client = client ?? http.Client();

  Future<String> createPaymentIntent({
    required String referenceType,
    required String referenceId,
    required double amount,
    required String returnUrl,
    required String userId,
    required String token,
  }) async {
    final baseUrl = ConfigService.apiBaseUrl;
    final url = Uri.parse('$baseUrl/api/payments/intent');

    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-User-ID': userId,
        },
        body: jsonEncode({
          'reference_type': referenceType,
          'reference_id': referenceId,
          'amount': amount,
          'return_url': returnUrl,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['form_url'] as String;
      } else {
        throw Exception('Failed to create payment intent: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error during payment initialization: $e');
    }
  }
}
