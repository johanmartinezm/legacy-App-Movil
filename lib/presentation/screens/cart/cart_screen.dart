import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:legacy_app/config/theme/app_theme.dart';
import 'package:legacy_app/domain/providers/cart_provider.dart';
import 'package:legacy_app/domain/models/cart_item.dart';
import '../../../config/utils/currency_formatter.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.legacyBlue1,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'MI CARRITO',
          style: GoogleFonts.barlow(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Consumer<CartProvider>(
                builder: (context, cart, child) {
                  if (cart.items.isEmpty) {
                    return Center(
                      child: Text(
                        'Tu carrito está vacío',
                        style: GoogleFonts.questrial(
                          fontSize: 18, 
                          color: Colors.grey[500],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return _buildCartItem(context, item, cart);
                    },
                  );
                },
              ),
            ),

            // Summary Section
            Consumer<CartProvider>(
              builder: (context, cart, child) => Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                decoration: BoxDecoration(
                  color: AppTheme.legacyBlue1,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      offset: const Offset(0, -5),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Subtotal:', cart.subtotal),
                    const SizedBox(height: 12),
                    _buildSummaryRow('IVA (19%):', cart.iva),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Divider(color: Colors.white12),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TOTAL A PAGAR:',
                          style: GoogleFonts.barlow(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(cart.total),
                          style: GoogleFonts.barlow(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: AppTheme.legacyGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Buttons
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: cart.items.isEmpty ? null : () {
                           context.push('/checkout');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.legacyGreen,
                          foregroundColor: Colors.white,
                          elevation: 5,
                          shadowColor: AppTheme.legacyGreen.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'PROCEDER AL PAGO →',
                          style: GoogleFonts.barlow(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () => context.pop(),
                        style: OutlinedButton.styleFrom(
                           side: const BorderSide(color: Colors.white30, width: 1.5),
                           foregroundColor: Colors.white,
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(16),
                           ),
                        ),
                        child: Text(
                          '← SEGUIR COMPRANDO',
                          style: GoogleFonts.barlow(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, CartItem item, CartProvider cart) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.legacyBlue2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            offset: const Offset(0, 5),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.barlow(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.legacyWhite,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tipo: ${item.type}',
                  style: GoogleFonts.questrial(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  CurrencyFormatter.format(item.price),
                  style: GoogleFonts.barlow(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppTheme.legacyGreen,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => cart.removeItem(item.id),
            icon: Container(
               padding: const EdgeInsets.all(10),
               decoration: BoxDecoration(
                 color: Colors.redAccent.withValues(alpha: 0.15),
                 borderRadius: BorderRadius.circular(10),
               ),
              child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.questrial(
            fontSize: 15, 
            color: Colors.grey[400],
          ),
        ),
        Text(
          CurrencyFormatter.format(value),
          style: GoogleFonts.barlow(
            fontWeight: FontWeight.bold, 
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
