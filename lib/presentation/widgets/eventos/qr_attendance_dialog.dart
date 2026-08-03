import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../config/theme/app_theme.dart';
import '../../../domain/providers/events_provider.dart';
import '../../../domain/providers/auth_provider.dart';

class QrAttendanceDialog extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const QrAttendanceDialog({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<QrAttendanceDialog> createState() => _QrAttendanceDialogState();
}

class _QrAttendanceDialogState extends State<QrAttendanceDialog> {
  String? _qrData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQrData();
  }

  Future<void> _loadQrData() async {
    final eventsProvider = context.read<EventsProvider>();
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;

    if (token == null) {
      setState(() {
        _error = 'Debes iniciar sesión';
        _isLoading = false;
      });
      return;
    }

    try {
      final data = await eventsProvider.getRegistrationQr(
        widget.eventId,
        token,
      );
      if (mounted) {
        setState(() {
          _qrData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Capturamos el error específico del backend/provider
          if (e.toString().contains('PAYMENT_REQUIRED')) {
            _error = 'PAGO_PENDIENTE';
          } else {
            _error = 'Ocurrió un error al cargar el QR';
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Mi Asistencia',
        textAlign: TextAlign.center,
        style: GoogleFonts.barlow(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.eventTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 24),

            // --- ESTADOS DE LA UI ---
            if (_isLoading)
              const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error == 'PAGO_PENDIENTE')
              _buildPaymentRequiredUI() // Función de ayuda para limpiar el código
            else if (_error != null)
              SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              )
            else if (_qrData != null)
              Column(
                children: [
                  Center(
                    child: QrImageView(
                      data: _qrData!,
                      version: QrVersions.auto,
                      size: 200.0,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppTheme.legacyBlue1,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AppTheme.legacyBlue1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Presenta este código al ingresar al evento.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.questrial(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Este QR es válido para todos tus talleres en este evento.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.questrial(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
        if (_error == 'PAGO_PENDIENTE')
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.legacyBlue1,
            ),
            onPressed: () {
              // Aquí iría tu lógica de navegación a la pasarela de pago
            },
            child: const Text(
              'Pagar Ahora',
              style: TextStyle(color: Colors.white),
            ),
          ),
      ],
    );
  }

  // Widget auxiliar para mostrar el error de pago de forma profesional
  Widget _buildPaymentRequiredUI() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.account_balance_wallet_outlined,
          size: 60,
          color: Colors.orange,
        ),
        const SizedBox(height: 16),
        Text(
          'Pago Pendiente',
          style: GoogleFonts.barlow(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          'Para generar tu QR de acceso, debes completar el pago de tu inscripción.',
          textAlign: TextAlign.center,
          style: GoogleFonts.questrial(fontSize: 14, color: Colors.grey[700]),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
