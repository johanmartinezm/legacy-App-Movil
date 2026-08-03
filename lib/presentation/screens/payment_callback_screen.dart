import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../data/config/config_service.dart';

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
      final url = Uri.parse('$baseUrl/api/payments/verify?tx_id=${widget.orderId}');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status'];
        
        setState(() {
          _isSuccess = status == 'APPROVED';
          if (!_isSuccess) {
            _errorMessage = 'El pago fue $status';
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _isSuccess = false;
          _errorMessage = 'Error validando pago: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _errorMessage = 'Error de conexión: $e';
        _isLoading = false;
      });
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
                    _isSuccess ? '¡Pago Exitoso!' : 'Pago Rechazado o Pendiente',
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
                  ElevatedButton(
                    onPressed: () {
                      context.go('/home');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD9A74A),
                      foregroundColor: const Color(0xFF050B15),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: Text(
                      'VOLVER AL INICIO',
                      style: GoogleFonts.barlow(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
