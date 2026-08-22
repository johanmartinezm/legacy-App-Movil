import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:legacy_app/config/theme/app_theme.dart';
import 'package:legacy_app/domain/providers/favorites_provider.dart';
import 'package:legacy_app/domain/models/content_model.dart';
import 'package:legacy_app/data/config/image_helper.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = context.watch<FavoritesProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MIS FAVORITOS',
          style: GoogleFonts.barlow(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: AppTheme.legacyWhite,
          ),
        ),
        backgroundColor: const Color(0xFF0B1A2E),
        foregroundColor: AppTheme.legacyWhite,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF050B15),
      body: favoritesProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : favoritesProvider.favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color: AppTheme.legacyWhite.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aún no tienes favoritos',
                    style: GoogleFonts.questrial(
                      fontSize: 18,
                      color: AppTheme.legacyWhite.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: favoritesProvider.favorites.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final item = favoritesProvider.favorites[index];
                return _buildFavoriteItem(context, item);
              },
            ),
    );
  }

  Widget _buildFavoriteItem(BuildContext context, ContentItem item) {
    return GestureDetector(
      onTap: () {
        context.push('/article-detail', extra: item);
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0B1A2E).withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF2A4A75).withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                image: DecorationImage(
                  image: NetworkImage(
                      ImageHelper.getProxiedImageUrl(item.imageUrl)),
                  fit: BoxFit.cover,
                ),
              ),
              child: item.type == 'Video'
                  ? const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 32,
                      ),
                    )
                  : null,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.legacyGold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.category.toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.legacyGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      style: GoogleFonts.barlow(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.legacyWhite,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: const Color(0xFF90A4BA),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.authorName ?? 'Desconocido',
                            style: GoogleFonts.questrial(
                              fontSize: 12,
                              color: const Color(0xFF90A4BA),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.bookmark, color: AppTheme.legacyGold),
              onPressed: () {
                context.read<FavoritesProvider>().toggleFavorite(item);
              },
            ),
          ],
        ),
      ),
    );
  }
}
