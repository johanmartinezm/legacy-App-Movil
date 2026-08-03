import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:legacy_app/domain/providers/favorites_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../domain/models/content_model.dart';
import '../../../data/services/graphql_service.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../data/config/image_helper.dart';

class VideoDetailScreen extends StatefulWidget {
  final ContentItem video;

  const VideoDetailScreen({super.key, required this.video});

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  late YoutubePlayerController _controller;


  @override
  void initState() {
    super.initState();
    // Use the videoUrl from the model, or fallback to a default if null/invalid
    final videoId =
        YoutubePlayer.convertUrlToId(widget.video.videoUrl ?? '') ??
        'ScMzIvxBSi4'; // Default to example if parsing fails

    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    );
  }

  @override
  void deactivate() {
    _controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: AppTheme.legacyBlue1,
          appBar: AppBar(
            backgroundColor: const Color(0xFF0B1A2E),
            leading: const BackButton(color: Colors.white),
            title: Text(
              widget.video.title,
              style: GoogleFonts.barlow(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.cast, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          body: Column(
            children: [
              // Video Player Area
              player, // The player widget
              // Scrollable Content
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Category Tag
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
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
                          widget.video.category.toUpperCase(),
                          style: GoogleFonts.barlow(
                            color: const Color(0xFF5BB0E6),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.video.title,
                      style: GoogleFonts.barlow(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.video.views ?? "0 vistas"} • ${widget.video.date ?? ""}',
                      style: GoogleFonts.questrial(
                        fontSize: 12,
                        color: const Color(0xFF90A4BA),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Interaction Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStat(
                          Icons.thumb_up_alt_outlined,
                          '${widget.video.likes ?? 0}',
                          const Color(0xFFE3C272),
                        ),
                        _buildStat(
                          Icons.remove_red_eye_outlined,
                          '${widget.video.views ?? 0}',
                          const Color(0xFF90A4BA),
                        ),
                        _buildActionBtn(
                          context,
                          Icons.bookmark_border,
                          'Guardar',
                        ),
                        _buildActionBtn(
                          context,
                          Icons.turn_right,
                          null,
                          onTap: () {
                            final text = widget.video.videoUrl != null
                                ? 'Mira este video en Legacy App:\n${widget.video.title}\n${widget.video.videoUrl}'
                                : 'Mira este contenido en Legacy App:\n${widget.video.title}';
                            Share.share(text); // ignore: deprecated_member_use
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Divider(color: Colors.white.withValues(alpha: 0.08)),
                    const SizedBox(height: 10),

                    // Author Profile
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1A2E).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFF5BB0E6).withValues(alpha: 0.2),
                            radius: 20,
                            backgroundImage: widget.video.authorAvatar != null
                                ? NetworkImage(ImageHelper.getProxiedImageUrl(
                                    widget.video.authorAvatar!))
                                : null,
                            child: widget.video.authorAvatar == null
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.video.authorName ??
                                      'Autor desconocido',
                                  style: GoogleFonts.barlow(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                if (widget.video.authorRole != null)
                                  Text(
                                    widget.video.authorRole!,
                                    style: GoogleFonts.questrial(
                                      fontSize: 11,
                                      color: const Color(0xFF90A4BA),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.legacyBlue3,
                              minimumSize: const Size(60, 30),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                            ),
                            child: const Text(
                              'Seguir',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Description
                    Text(
                      'Descripción',
                      style: GoogleFonts.barlow(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    HtmlWidget(
                      widget.video.description ??
                          widget.video.fullContent ??
                          'Sin descripción',
                      textStyle: GoogleFonts.questrial(
                        fontSize: 14,
                        color: const Color(0xFFE8EEF5).withValues(alpha: 0.9),
                        height: 1.5,
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
                            debugPrint('Error en navegación interna desde descripción de video: $e');
                          }
                        }

                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                          return true;
                        }
                        return false;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Related
                    if (widget.video.relatedContent != null &&
                        widget.video.relatedContent!.isNotEmpty) ...[
                      Text(
                        'Videos Relacionados',
                        style: GoogleFonts.barlow(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...widget.video.relatedContent!.map(
                        (e) => _buildRelatedVideo(e),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
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

  Widget _buildActionBtn(
    BuildContext context,
    IconData icon,
    String? label, {
    VoidCallback? onTap,
  }) {
    if (label == 'Guardar') {
      final isFav = context.watch<FavoritesProvider>().isFavorite(
        _article()?.id ?? widget.video.id,
      );
      return GestureDetector(
        onTap: () {
          context.read<FavoritesProvider>().toggleFavorite(widget.video);
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }

  ContentItem? _article() => widget.video;

  Widget _buildRelatedVideo(ContentItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1A2E).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 60,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1A2E),
                    borderRadius: BorderRadius.circular(8),
                        image: item.imageUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(
                                    ImageHelper.getProxiedImageUrl(
                                        item.imageUrl)),
                                fit: BoxFit.cover,
                              )
                            : null,
                  ),
                  child: const Center(
                    child: Icon(Icons.play_arrow, color: Colors.white),
                  ),
                ),
                if (item.duration != null)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      color: Colors.black87,
                      child: Text(
                        item.duration!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
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
                    '${item.authorName!} • ${item.views ?? ''}',
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
