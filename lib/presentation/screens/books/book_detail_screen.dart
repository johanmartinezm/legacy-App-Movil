import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:legacy_app/domain/utils/sanitizar_html.dart';
import '../../../domain/models/book_model.dart';
import '../../../domain/utils/abrir_en_lso.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../data/config/image_helper.dart';
import '../../widgets/boton_volver.dart';

class BookDetailScreen extends StatelessWidget {
  final GraphqlBook book;

  const BookDetailScreen({super.key, required this.book});


  Future<void> _comprarEnLso(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    if (await abrirEnLso(book.url)) return;

    messenger.showSnackBar(
      const SnackBar(
        content: Text(mensajeLsoNoAbre),
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.legacyBlue1,
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
      leading: const BotonVolver(),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Mismo degradado de panel que el resto de la app, en lugar del
            // gris claro que tenia esta pantalla.
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppTheme.legacySurface, AppTheme.legacyBlue1],
                ),
              ),
            ),
            if (book.imageUrl != null)
              Center(
                child: Hero(
                  tag: 'book_image_${book.id}',
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
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
      child: Icon(Icons.book, size: 100, color: Color(0xFF9FB2C2)),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BIBLIOTECA LEGACY',
          style: GoogleFonts.barlow(
            fontSize: 12,
            color: AppTheme.legacyActive,
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
            color: Colors.white,
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
        color: (isOutOfStock ? Colors.redAccent : AppTheme.legacyGreenDark)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (isOutOfStock ? Colors.redAccent : AppTheme.legacyGreenDark)
              .withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOutOfStock ? Icons.error_outline : Icons.check_circle_outline,
            size: 16,
            color: isOutOfStock ? Colors.redAccent : AppTheme.legacyGreenDark,
          ),
          const SizedBox(width: 8),
          Text(
            isOutOfStock ? 'AGOTADO' : 'DISPONIBLE',
            style: GoogleFonts.questrial(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isOutOfStock ? Colors.redAccent : AppTheme.legacyGreenDark,
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
            color: Colors.white,
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
            color: const Color(0xFF9FB2C2),
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
        color: AppTheme.legacySurface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.legacyBlue3.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Inversión:',
                style: GoogleFonts.questrial(
                  color: const Color(0xFF9FB2C2),
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
                        color: Color(0xFF9FB2C2),
                        fontSize: 14,
                      ),
                    ),
                  Text(
                    book.price ?? 'Consultar',
                    style: GoogleFonts.barlow(
                      color: Colors.white,
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
        color: AppTheme.legacyBlue1,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: isOutOfStock ? null : () => _comprarEnLso(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.legacyActive,
            foregroundColor: AppTheme.legacyBlue1,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            disabledBackgroundColor: AppTheme.legacySurface,
            disabledForegroundColor: const Color(0xFF9FB2C2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.open_in_new),
              const SizedBox(width: 12),
              Text(
                isOutOfStock ? 'PRODUCTO AGOTADO' : 'Comprar en LSO',
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
