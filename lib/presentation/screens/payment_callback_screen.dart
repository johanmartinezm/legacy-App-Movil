import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../data/config/config_service.dart';
import '../../domain/providers/auth_provider.dart';
import '../../domain/providers/events_provider.dart';

class PaymentCallbackScreen extends StatefulWidget {
  final String orderId;

  const PaymentCallbackScreen({super.key, required this.orderId});

  @override
  State<PaymentCallbackScreen> createState() => _PaymentCallbackScreenState();
}

class _PaymentCallbackScreenState extends State<PaymentCallbackScreen> {
  bool _isLoading = true;
  bool _isSuccess = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _verifyPayment();
  }

  Future<void> _verifyPayment() async {
    try {
      final baseUrl = ConfigService.apiBaseUrl;

      if (widget.orderId.isEmpty) {
        setState(() {
          _isSuccess = false;
          _errorMessage =
              'No pudimos identificar tu pago. Revisa "Mi credencial" en unos minutos.';
          _isLoading = false;
        });
        return;
      }

      final url = Uri.parse(
        '$baseUrl/api/payments/verify?tx_id=${widget.orderId}',
      );

      // /api/payments/verify está bajo AuthMiddleware: esta llamada iba sin
      // cabecera y respondía 401, así que la verificación fallaba siempre
      // aunque el usuario hubiera pagado.
      final token = context.read<AuthProvider>().token;
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status'];
        final aprobado = status == 'APPROVED';

        // Con el pago aprobado, el backend ya pasó la inscripción a
        // 'confirmed'. Se recargan para que "Mi credencial" y el botón del
        // evento reflejen el cambio sin tener que reiniciar la app.
        if (aprobado && token != null && mounted) {
          await context.read<EventsProvider>().loadMyRegistrations(token);
        }

        if (!mounted) return;
        setState(() {
          _isSuccess = aprobado;
          if (!_isSuccess) {
            _errorMessage = _mensajeDeEstado(status?.toString());
          }
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _isSuccess = false;
          _errorMessage = response.statusCode == 401
              ? 'Tu sesión expiró. Vuelve a iniciar sesión y revisa "Mi credencial".'
              : 'No pudimos confirmar el pago (${response.statusCode}). Si el cargo se hizo, aparecerá en "Mi credencial".';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSuccess = false;
        _errorMessage =
            'No pudimos confirmar el pago por un problema de conexión. Si el cargo se hizo, aparecerá en "Mi credencial".';
        _isLoading = false;
      });
    }
  }

  /// El estado que devuelve la pasarela es un código; al usuario hay que
  /// decirle qué significa y qué puede hacer.
  String _mensajeDeEstado(String? status) {
    switch (status) {
      case 'PENDING':
        return 'Tu pago está en proceso. En cuanto el banco lo confirme, tu cupo quedará listo en "Mi credencial".';
      case 'DECLINED':
      case 'REJECTED':
        return 'El banco rechazó el pago. Tu cupo sigue reservado: puedes intentarlo de nuevo desde el evento.';
      case 'FAILED':
        return 'El pago no se completó. Tu cupo sigue reservado y puedes reintentarlo desde el evento.';
      default:
        return 'El pago quedó en estado "$status". Tu cupo sigue reservado.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B15),
      body: Center(
        child: _isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFFD9A74A)),
                  const SizedBox(height: 24),
                  Text(
                    'Verificando tu pago con el banco...',
                    style: GoogleFonts.barlow(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isSuccess ? Icons.check_circle : Icons.error,
                    color: _isSuccess ? Colors.green : Colors.red,
                    size: 80,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isSuccess
                        ? '¡Pago Exitoso!'
                        : 'Pago Rechazado o Pendiente',
                    style: GoogleFonts.barlow(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!_isSuccess)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.questrial(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                  // Tras un pago aprobado lo que el usuario quiere es su
                  // código de acceso, no la pantalla de inicio.
                  ElevatedButton(
                    key: const Key('callback-ver-credencial'),
                    onPressed: () => context.go('/mi-credencial'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD9A74A),
                      foregroundColor: const Color(0xFF050B15),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      _isSuccess ? 'VER MI CREDENCIAL' : 'REVISAR MI CREDENCIAL',
                      style: GoogleFonts.barlow(fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: Text(
                      'Volver al inicio',
                      style: GoogleFonts.questrial(color: Colors.white70),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
