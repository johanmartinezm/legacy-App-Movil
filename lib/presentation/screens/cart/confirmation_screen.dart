import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:legacy_app/config/theme/app_theme.dart';
import 'package:legacy_app/domain/providers/cart_provider.dart';
import '../../../config/utils/currency_formatter.dart';

class ConfirmationScreen extends StatelessWidget {
  const ConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // We can clear cart here or on "Volver al Inicio"
    // For now purely visual as per design
    final cart = Provider.of<CartProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
             // Header
            Container(
              color: AppTheme.legacyGreen,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Center(
                child: Text(
                  'CONFIRMACIÓN',
                  style: GoogleFonts.barlow(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Check Icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: AppTheme.legacyGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 60),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '¡Compra Exitosa!',
                      style: GoogleFonts.barlow(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.legacyGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tu pago ha sido procesado correctamente',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.questrial(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 32),

                    // Summary Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[50], 
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                               const Icon(Icons.receipt_long, color: Colors.grey),
                               const SizedBox(width: 8),
                               Text('Resumen de tu Compra', style: GoogleFonts.barlow(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          ...cart.items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                const Icon(Icons.check, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${item.title} - ${CurrencyFormatter.format(item.price)}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          )),
                          const SizedBox(height: 16),
                           const Divider(),
                           const SizedBox(height: 16),
                           Row(
                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                             children: [
                               const Text('Subtotal:'),
                               Text(CurrencyFormatter.format(cart.subtotal)),
                             ],
                           ),
                             Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                               const Text('IVA (19%):'),
                               Text(CurrencyFormatter.format(cart.iva)),
                             ],
                           ),
                           const SizedBox(height: 16),
                             Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                               Text('TOTAL PAGADO:', style: GoogleFonts.barlow(fontWeight: FontWeight.bold)),
                               Text(CurrencyFormatter.format(cart.total), style: GoogleFonts.barlow(fontWeight: FontWeight.bold, color: AppTheme.legacyGreen, fontSize: 18)),
                             ],
                           ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Container(
                      padding: const EdgeInsets.all(12),
                       decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.email_outlined, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Hemos enviado la confirmación y los detalles de tu compra a tu correo electrónico',
                              style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () {},
                         icon: const Icon(Icons.download, size: 18),
                        label: const Text('Descargar Comprobante'),
                        style: OutlinedButton.styleFrom(
                           foregroundColor: Colors.blue,
                           side: const BorderSide(color: Colors.blue),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
             // Bottom Button
             Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    cart.clearCart(); // Clean cart on exit
                    context.go('/home');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.legacyGreen,
                    foregroundColor: Colors.white,
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'VOLVER AL INICIO',
                    style: GoogleFonts.barlow(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ),
             const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
