import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:legacy_app/data/config/config_service.dart';

class PaymentService {
  final http.Client _client;

  PaymentService({http.Client? client}) : _client = client ?? http.Client();

  /// Inicia el pago y devuelve la URL del formulario de la pasarela.
  ///
  /// [amount] se sigue enviando, pero **el servidor manda**: contrasta el
  /// importe con el precio real del evento y responde 409 si no coinciden. Antes
  /// se cobraba tal cual lo que enviara el cliente.
  ///
  /// [userId] ya no viaja: el backend toma el usuario del token. Se conserva el
  /// parámetro para no romper a quien llame, pero se ignora.
  Future<String> createPaymentIntent({
    required String referenceType,
    required String referenceId,
    required double amount,
    required String returnUrl,
    required String token,
    // Informativo: queda registrado lo que el usuario eligió, pero los medios
    // de pago los muestra y los decide la pasarela.
    String? paymentMethod,
  }) async {
    final baseUrl = ConfigService.apiBaseUrl;
    final url = Uri.parse('$baseUrl/api/payments/intent');

    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'reference_type': referenceType,
          'reference_id': referenceId,
          'amount': amount,
          'return_url': returnUrl,
          if (paymentMethod != null) 'payment_method': paymentMethod,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['form_url'] as String;
      }

      // El servidor valida el importe contra el precio del evento; conviene
      // decir qué pasó en vez de soltar el cuerpo crudo de la respuesta.
      switch (response.statusCode) {
        case 409:
          throw Exception(
            'El precio de este evento cambió. Vuelve a abrirlo para ver el importe actual.',
          );
        case 400:
          throw Exception('Este evento es gratuito: no hace falta pagar.');
        case 404:
          throw Exception('Este evento ya no está disponible.');
        case 401:
          throw Exception('Tu sesión expiró. Vuelve a iniciar sesión.');
        case 502:
          // La pasarela rechazó la petición. Tu cupo ya quedó reservado antes
          // de llegar aquí, y eso es lo que al usuario le importa saber.
          throw Exception(
            'La pasarela de pagos no está disponible en este momento. '
            'Tu cupo quedó reservado: inténtalo de nuevo más tarde desde el evento.',
          );
        default:
          throw Exception(
            'No pudimos iniciar el pago (${response.statusCode}). Inténtalo más tarde.',
          );
      }
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Error de conexión al iniciar el pago: $e');
    }
  }
}
