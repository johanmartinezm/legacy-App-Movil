import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/content_model.dart';

class ContentSearchDelegate extends SearchDelegate<ContentItem?> {
  final List<ContentItem> allPosts;

  ContentSearchDelegate({required this.allPosts});

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      scaffoldBackgroundColor: const Color(0xFF050B15),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0B1A2E),
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: GoogleFonts.questrial(color: const Color(0xFF90A4BA)),
        border: InputBorder.none,
      ),
      textTheme: TextTheme(
        titleLarge: GoogleFonts.questrial(color: Colors.white, fontSize: 18),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.white),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResultsList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResultsList(context);
  }

  Widget _buildSearchResultsList(BuildContext context) {
    final filtered = allPosts.where((post) {
      final titleMatch = post.title.toLowerCase().contains(query.toLowerCase());
      final descMatch = (post.description ?? '').toLowerCase().contains(query.toLowerCase());
      return titleMatch || descMatch;
    }).toList();

    if (filtered.isEmpty) {
      return Container(
        color: const Color(0xFF050B15),
        child: Center(
          child: Text(
            'No se encontró contenido coincidente.',
            style: GoogleFonts.questrial(
              color: const Color(0xFF90A4BA),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFF050B15),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final item = filtered[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1A2E).withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF2A4A75).withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            child: InkWell(
              onTap: () {
                close(context, item);
                if (item.type == 'video') {
                  context.push('/video-detail', extra: item);
                } else {
                  context.push('/article-detail', extra: item);
                }
              },
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF132A44),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF1E3A5F).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Icon(
                      _getIconForType(item.type),
                      color: const Color(0xFFD9A74A),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.barlow(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.description ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.questrial(
                            fontSize: 12,
                            color: const Color(0xFF90A4BA),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Icons.play_circle_outline;
      case 'podcast':
        return Icons.headset;
      case 'book':
      case 'libros':
        return Icons.book_outlined;
      default:
        return Icons.article_outlined;
    }
  }
}
