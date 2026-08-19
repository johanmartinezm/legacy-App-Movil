import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:legacy_app/domain/utils/sanitizar_html.dart';
import '../../../domain/models/book_model.dart';
import '../../../domain/models/cart_item.dart';
import '../../../domain/providers/cart_provider.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../data/config/image_helper.dart';

class BookDetailScreen extends StatelessWidget {
  final GraphqlBook book;

  const BookDetailScreen({super.key, required this.book});

  double _parsePrice(String? priceStr) {
    if (priceStr == null) return 0.0;
    // Remove currency symbols, nbsp, and dots for grouping
    String cleaned = priceStr.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  void _addToCart(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    
    final item = CartItem(
      id: book.id,
      title: book.name,
      type: 'Libro',
      price: _parsePrice(book.price),
    );

    cartProvider.addItem(item);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '¡${book.name} añadido al carrito!',
          style: GoogleFonts.questrial(),
        ),
        backgroundColor: AppTheme.legacyOrange,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'VER CARRITO',
          textColor: Colors.white,
          onPressed: () => context.push('/cart'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildStockBadge(),
                  const SizedBox(height: 32),
                  _buildDescription(),
                  const SizedBox(height: 40),
                  _buildPriceSection(),
                  const SizedBox(height: 100), // Space for bottom buttons
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomBar(context),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      backgroundColor: AppTheme.legacyBlue1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: Colors.grey[100]),
            if (book.imageUrl != null)
              Center(
                child: Hero(
                  tag: 'book_image_${book.id}',
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Image.network(
                      ImageHelper.getProxiedImageUrl(book.imageUrl!),
                      height: 300,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholder(),
                    ),
                  ),
                ),
              )
            else
              _buildPlaceholder(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Icon(Icons.book, size: 100, color: Colors.grey),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BIBLIOTECA LEGACY',
          style: GoogleFonts.questrial(
            fontSize: 14,
            color: AppTheme.legacyOrange,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          book.name,
          style: GoogleFonts.barlow(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.legacyBlue1,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildStockBadge() {
    final isOutOfStock = book.stockStatus == 'OUT_OF_STOCK';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOutOfStock ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOutOfStock ? Colors.red[200]! : Colors.green[200]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOutOfStock ? Icons.error_outline : Icons.check_circle_outline,
            size: 16,
            color: isOutOfStock ? Colors.red[700] : Colors.green[700],
          ),
          const SizedBox(width: 8),
          Text(
            isOutOfStock ? 'AGOTADO' : 'DISPONIBLE',
            style: GoogleFonts.questrial(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isOutOfStock ? Colors.red[700] : Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sobre este libro',
          style: GoogleFonts.barlow(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.legacyBlue1,
          ),
        ),
        const SizedBox(height: 16),
        HtmlWidget(
          // La descripción llega del WordPress de LSO, que es contenido de fuera.
          sanitizarHtml(
            (book.description != null && book.description!.isNotEmpty)
                ? book.description!
                : (book.shortDescription ?? 'No hay descripción disponible.'),
          ),
          textStyle: GoogleFonts.questrial(
            fontSize: 16,
            color: Colors.black87,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Inversión:',
                style: GoogleFonts.questrial(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (book.regularPrice != null && book.regularPrice != book.price)
                    Text(
                      book.regularPrice!,
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  Text(
                    book.price ?? 'Consultar',
                    style: GoogleFonts.barlow(
                      color: AppTheme.legacyBlue1,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final isOutOfStock = book.stockStatus == 'OUT_OF_STOCK';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: isOutOfStock ? null : () => _addToCart(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.legacyOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 0,
            disabledBackgroundColor: Colors.grey[300],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_shopping_cart),
              const SizedBox(width: 12),
              Text(
                isOutOfStock ? 'PRODUCTO AGOTADO' : 'Añadir al carrito',
                style: GoogleFonts.barlow(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
