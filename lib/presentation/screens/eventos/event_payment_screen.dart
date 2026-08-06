import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:legacy_app/domain/models/event_model.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:legacy_app/domain/providers/auth_provider.dart';
import 'package:legacy_app/domain/providers/events_provider.dart';
import '../../../config/utils/currency_formatter.dart';
import '../../../data/services/payment_service.dart';

class EventPaymentScreen extends StatefulWidget {
  final EventModel event;

  const EventPaymentScreen({super.key, required this.event});

  @override
  State<EventPaymentScreen> createState() => _EventPaymentScreenState();
}

class _EventPaymentScreenState extends State<EventPaymentScreen> {
  String _selectedPaymentMethod = 'credit_card'; // 'credit_card' or 'pse'
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Antes estos tres campos no tenian controlador ni valor inicial: lo que se
  // veia eran los `hintText` de ejemplo ("Juan Perez Garcia"), asi que el
  // formulario era decorativo y nada de lo escrito se leia.
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  bool _datosCargados = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_datosCargados) return;

    // Se rellena una sola vez: si el usuario corrige un dato, un segundo
    // prellenado le borraria la correccion.
    final auth = context.read<AuthProvider>();
    _nombreController.text = auth.fullName ?? '';
    _emailController.text = auth.email ?? '';
    _telefonoController.text = auth.phone ?? '';
    _datosCargados = true;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    // El formulario declaraba _formKey y nunca lo validaba.
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token == null) {
        throw Exception('Usuario no autenticado');
      }

      // La inscripción se crea ANTES de salir a la pasarela. El backend la deja
      // en 'pending_payment' porque el evento no es gratuito, y la confirma
      // cuando el cobro se aprueba. Sin este paso no quedaba ni rastro de quién
      // había intentado comprar: en el camino de pago la app iba directa a la
      // pasarela y nunca llamaba a /register.
      final eventsProvider = context.read<EventsProvider>();
      final inscrito = await eventsProvider.registerUserToEvent(
        widget.event.id,
        token,
      );
      if (!inscrito) {
        throw Exception(
          eventsProvider.errorMessage ?? 'No se pudo reservar tu cupo',
        );
      }

      final paymentService = PaymentService();
      final formUrl = await paymentService.createPaymentIntent(
        referenceType: 'EVENT',
        referenceId: widget.event.id,
        amount: widget.event.price,
        returnUrl: 'legacyapp://payment-callback',
        token: token,
      );
      
      final uri = Uri.parse(formUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        // Note: The app should listen for the deep link `legacyapp://payment-callback`
        // in the main router, which would then call /api/payments/verify to confirm.
        // For UX flow, we can go back to events screen now and let deep link handle success.
        if (mounted) {
          context.go('/eventos');
        }
      } else {
        throw Exception('No se pudo abrir la pasarela de pagos.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B15),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Confirmar Registro',
          style: GoogleFonts.barlow(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.8, -0.8),
            radius: 1.5,
            colors: [
              Color(0xFF13304A), // Accent steel blue
              Color(0xFF0E2C3B), // Dark blue-gray
              Color(0xFF050B15), // Ultra dark base
            ],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Summary Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B1A2E).withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF1E3A5F).withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.event.title,
                                style: GoogleFonts.barlow(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${widget.event.date} • ${widget.event.location ?? "Online"}',
                                style: GoogleFonts.questrial(
                                  fontSize: 14,
                                  color: const Color(0xFF90A4BA),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '1 entrada',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(
                                      widget.event.price,
                                    ),
                                    style: GoogleFonts.barlow(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: const Color(
                                        0xFFD9A74A,
                                      ), // Gold premium price
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Participant Details
                        Text(
                          'Datos del Participante:',
                          style: GoogleFonts.barlow(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          'Nombre Completo',
                          'Juan Perez Garcia',
                          key: const Key('pago-nombre'),
                          controller: _nombreController,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Escribe el nombre del participante'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          'Email',
                          'juan.perez@email.com',
                          key: const Key('pago-email'),
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            final valor = v?.trim() ?? '';
                            if (valor.isEmpty) return 'Escribe un correo';
                            // Suficiente para atajar erratas; la validacion de
                            // verdad la hace el envio del correo.
                            final ok = RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            ).hasMatch(valor);
                            return ok ? null : 'Ese correo no parece válido';
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          'Teléfono',
                          '+57 300 123 4567',
                          key: const Key('pago-telefono'),
                          controller: _telefonoController,
                          keyboardType: TextInputType.phone,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Escribe un teléfono de contacto'
                              : null,
                        ),

                        const SizedBox(height: 24),

                        // Payment Method
                        Text(
                          'Método de Pago:',
                          style: GoogleFonts.barlow(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildPaymentOption(
                          'Tarjeta Crédito/Débito',
                          'credit_card',
                          isSelected: _selectedPaymentMethod == 'credit_card',
                        ),
                        const SizedBox(height: 12),
                        _buildPaymentOption(
                          'PSE - Pago en Línea',
                          'pse',
                          isSelected: _selectedPaymentMethod == 'pse',
                        ),

                        const SizedBox(height: 24),

                        // Total
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B1A2E).withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF1E3A5F).withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TOTAL A PAGAR:',
                                style: GoogleFonts.barlow(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF90A4BA),
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(widget.event.price),
                                style: GoogleFonts.barlow(
                                  color: const Color(
                                    0xFFD9A74A,
                                  ), // Gold premium price
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Pay Button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD9A74A), // Premium gold
                      foregroundColor: const Color(
                        0xFF050B15,
                      ), // Dark contrast text
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading 
                        ? const CircularProgressIndicator(color: Color(0xFF050B15))
                        : Text(
                            'PROCEDER AL PAGO',
                            style: GoogleFonts.barlow(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint, {
    Key? key,
    TextEditingController? controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: GoogleFonts.questrial(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: GoogleFonts.questrial(color: const Color(0xFF90A4BA)),
        hintStyle: GoogleFonts.questrial(color: Colors.white.withValues(alpha: 0.3)),
        filled: true,
        fillColor: const Color(0xFF0B1A2E).withValues(alpha: 0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: const Color(0xFF1E3A5F).withValues(alpha: 0.4),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: const Color(0xFF1E3A5F).withValues(alpha: 0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF5A93C4), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    String label,
    String value, {
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF13304A).withValues(alpha: 0.4)
              : const Color(0xFF0B1A2E).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00F2FE)
                : const Color(0xFF1E3A5F).withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.questrial(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF90A4BA),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFF00F2FE)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF00F2FE)
                      : const Color(0xFF90A4BA),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Color(0xFF050B15))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
