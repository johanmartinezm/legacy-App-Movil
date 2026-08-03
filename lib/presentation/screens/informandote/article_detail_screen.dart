import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:legacy_app/domain/providers/favorites_provider.dart';
import '../../../domain/models/content_model.dart';
import '../../../../config/theme/app_theme.dart';

import 'package:legacy_app/domain/providers/auth_provider.dart';
import 'package:legacy_app/data/services/post_service.dart';
import 'package:legacy_app/data/services/graphql_service.dart';
import 'package:legacy_app/data/config/image_helper.dart';

class ArticleDetailScreen extends StatefulWidget {
  final ContentItem article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final PostService _postService = PostService();
  late ContentItem _article;
  bool _isLiking = false;

  @override
  void initState() {
    super.initState();
    _article = widget.article;
    _recordView();
    _fetchLikeStatus();
  }

  Future<void> _recordView() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      await _postService.recordView(
        _article.id,
        title: _article.title,
        token: token,
      );
    } catch (e) {
      debugPrint('Error recording view: $e');
    }
  }

  Future<void> _fetchLikeStatus() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final status = await _postService.getLikeStatus(
        _article.id,
        token: token,
      );
      if (mounted) {
        setState(() {
          _article = _article.copyWith(
            likes: status['total_likes'] as int,
            isLikedByMe: status['is_liked'] as bool,
            totalViews: status['total_views'] as int,
          );
        });
      }
    } catch (e) {
      debugPrint('Error fetching likes/views: $e');
    }
  }

  Future<void> _toggleLike() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para dar like')),
      );
      return;
    }

    if (_isLiking) return;

    // Optimistic update
    final wasLiked = _article.isLikedByMe;
    final currentLikes = _article.likes ?? 0;

    setState(() {
      _isLiking = true;
      _article = _article.copyWith(
        isLikedByMe: !wasLiked,
        likes: wasLiked ? currentLikes - 1 : currentLikes + 1,
      );
    });

    try {
      final status = await _postService.toggleLike(
        _article.id,
        token: authProvider.token,
      );
      if (mounted) {
        setState(() {
          _article = _article.copyWith(
            likes: status['total_likes'] as int,
            isLikedByMe: status['is_liked'] as bool,
          );
          _isLiking = false;
        });
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _article = _article.copyWith(
            isLikedByMe: wasLiked,
            likes: currentLikes,
          );
          _isLiking = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al procesar like. Reintenta más tarde.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.legacyBlue1,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 4.0, bottom: 4.0),
              child: CircleAvatar(
                backgroundColor: const Color(0xFF0B1A2E).withValues(alpha: 0.6),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            actions: [
              CircleAvatar(
                backgroundColor: const Color(0xFF0B1A2E).withValues(alpha: 0.6),
                child: IconButton(
                  icon: const Icon(Icons.share, color: Colors.white, size: 18),
                  onPressed: () {
                    Share.share(
                      'Lee este artículo en Legacy App:\n${_article.title}',
                    ); // ignore: deprecated_member_use
                  },
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: const Color(0xFF0B1A2E).withValues(alpha: 0.6),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white, size: 18),
                  tooltip: 'Menú',
                  onSelected: (value) {
                    switch (value) {
                      case 'profile':
                        context.push('/profile');
                        break;
                      case 'favorites':
                        context.push('/favorites');
                        break;
                      case 'sec_home':
                        context.go('/home?tab=0');
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'profile',
                          child: ListTile(
                            leading: Icon(Icons.person),
                            title: Text('Mi perfil'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'favorites',
                          child: ListTile(
                            leading: Icon(Icons.bookmark_outline),
                            title: Text('Artículos guardados'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem<String>(
                          value: 'sec_home',
                          child: ListTile(
                            leading: Icon(Icons.home_outlined),
                            title: Text('Volver al inicio'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                ),
              ),
              const SizedBox(width: 16),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                ImageHelper.getProxiedImageUrl(_article.imageUrl),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: Colors.grey[300]),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5BB0E6).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF5BB0E6).withValues(alpha: 0.3), width: 1),
                    ),
                    child: Text(
                      _article.category.toUpperCase(),
                      style: GoogleFonts.barlow(
                        color: const Color(0xFF5BB0E6),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _article.title,
                    style: GoogleFonts.barlow(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF5BB0E6).withValues(alpha: 0.2),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                        ),
                        child: const Center(
                          child: Icon(Icons.person, color: Colors.white, size: 14),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_article.authorName ?? 'Legacy Research'} • ${_article.readTime ?? '8 min'}',
                        style: GoogleFonts.questrial(
                          fontSize: 13,
                          color: const Color(0xFF90A4BA),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.white.withValues(alpha: 0.08)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStat(
                        _article.isLikedByMe
                            ? Icons.thumb_up
                            : Icons.thumb_up_alt_outlined,
                        '${_article.likes ?? 0}',
                        _article.isLikedByMe
                            ? const Color(0xFF5BB0E6)
                            : const Color(0xFFE3C272),
                        onTap: _toggleLike,
                      ),
                      _buildStat(
                        Icons.remove_red_eye_outlined,
                        '${_article.totalViews ?? 0}',
                        const Color(0xFF90A4BA),
                      ),
                      _buildActionBtn(
                        context,
                        Icons.bookmark_border,
                        'Guardar',
                      ),
                      _buildActionBtn(context, Icons.turn_right, null),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Divider(color: Colors.white.withValues(alpha: 0.08)),
                  const SizedBox(height: 16),
                  HtmlWidget(
                    _article.fullContent ??
                        _article.description ??
                        'Contenido no disponible',
                    textStyle: GoogleFonts.questrial(
                      fontSize: 14,
                      height: 1.5,
                      color: const Color(0xFFE8EEF5).withValues(alpha: 0.9),
                    ),
                    customStylesBuilder: (element) {
                      if (element.localName == 'h1') {
                        return {'font-size': '20px', 'font-weight': 'bold', 'color': 'white', 'margin-top': '16px', 'margin-bottom': '8px'};
                      }
                      if (element.localName == 'h2') {
                        return {'font-size': '18px', 'font-weight': 'bold', 'color': 'white', 'margin-top': '16px', 'margin-bottom': '8px'};
                      }
                      if (element.localName == 'h3') {
                        return {'font-size': '16px', 'font-weight': 'bold', 'color': 'white', 'margin-top': '12px', 'margin-bottom': '6px'};
                      }
                      if (element.localName == 'p') {
                        return {'font-size': '14px', 'line-height': '1.5', 'margin-bottom': '12px'};
                      }
                      return null;
                    },
                    onTapUrl: (url) async {
                      final uri = Uri.parse(url);
                      
                      // Si es un vínculo interno de Legacy Network, navegar dentro del app
                      final isInternal = uri.host.contains('legacynetworkco.com') || uri.host.isEmpty;
                      
                      if (isInternal) {
                        try {
                          final slug = uri.pathSegments.lastWhere((s) => s.isNotEmpty, orElse: () => '');
                          if (slug.isNotEmpty) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Cargando artículo...'), duration: Duration(milliseconds: 700)),
                              );
                            }
                            
                            final graphqlService = GraphqlService();
                            final post = await graphqlService.getPostBySlug(slug);
                            
                            if (post != null && mounted) {
                              context.push('/article-detail', extra: post.toContentItem());
                              return true;
                            }
                          }
                        } catch (e) {
                          debugPrint('Error en navegación interna de artículo: $e');
                        }
                      }

                      // Fallback a navegador externo
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                        return true;
                      }
                      return false;
                    },
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'PROFUNDICE',
                    style: GoogleFonts.barlow(
                      color: const Color(0xFFE3C272),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => context.go('/programas'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1A2E).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Icon(Icons.school_outlined, color: Color(0xFF5BB0E6), size: 22),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Programa completo en LSO',
                                  style: GoogleFonts.barlow(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Escuela · precio especial para clientes',
                                  style: GoogleFonts.questrial(
                                    color: const Color(0xFF90A4BA),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8DCCA).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'L',
                              style: GoogleFonts.barlow(
                                color: const Color(0xFFE3C272),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  if (_article.relatedContent != null &&
                      _article.relatedContent!.isNotEmpty) ...[
                    Text(
                      'Artículos Relacionados',
                      style: GoogleFonts.barlow(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._article.relatedContent!.map(
                      (e) => _buildRelatedItem(e),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
    IconData icon,
    String text,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.questrial(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(BuildContext context, IconData icon, String? label) {
    if (label == 'Guardar') {
      final isFav = context.watch<FavoritesProvider>().isFavorite(_article.id);
      return GestureDetector(
        onTap: () {
          context.read<FavoritesProvider>().toggleFavorite(_article);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isFav ? const Color(0xFFE3C272).withValues(alpha: 0.15) : const Color(0xFF0B1A2E).withValues(alpha: 0.4),
            border: Border.all(
              color: isFav ? const Color(0xFFE3C272) : Colors.white.withValues(alpha: 0.08),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                isFav ? Icons.bookmark : Icons.bookmark_border,
                size: 18,
                color: isFav ? const Color(0xFFE3C272) : const Color(0xFF90A4BA),
              ),
              if (label != null) ...[
                const SizedBox(width: 4),
                Text(
                  isFav ? 'Guardado' : label,
                  style: GoogleFonts.questrial(
                    color: isFav ? const Color(0xFFE3C272) : const Color(0xFF90A4BA),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1A2E).withValues(alpha: 0.4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF90A4BA)),
          if (label != null) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.questrial(
                color: const Color(0xFF90A4BA),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRelatedItem(ContentItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1A2E).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF0B1A2E),
              borderRadius: BorderRadius.circular(8),
              image: item.imageUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(
                        ImageHelper.getProxiedImageUrl(item.imageUrl),
                      ),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.barlow(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (item.authorName != null)
                  Text(
                    'Por ${item.authorName} • ${item.readTime ?? item.duration ?? ''}',
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
    );
  }
}
