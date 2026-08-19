import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../domain/models/graphql_post_model.dart';
import '../../../domain/models/content_model.dart';
import '../../../domain/models/custom_content_model.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/services/graphql_service.dart';
import '../../../data/services/custom_content_service.dart';
import '../../../data/services/video_canal_service.dart';
import '../../../domain/models/video_canal_model.dart';
import '../../../domain/utils/busqueda_global.dart';

class InformandoteScreen extends StatefulWidget {
  const InformandoteScreen({super.key});

  @override
  State<InformandoteScreen> createState() => _InformandoteScreenState();
}

class _InformandoteScreenState extends State<InformandoteScreen> {
  final GraphqlService _graphqlService = GraphqlService();
  final CustomContentService _customContentService = CustomContentService();
  final VideoCanalService _videoCanalService = VideoCanalService();
  final ScrollController _scrollController = ScrollController();

  List<ContentItem> _posts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _endCursor;
  // Flag para prevenir setState() después de dispose()
  bool _disposed = false;
  
  // Selected filter matching: Todo, Artículos, Podcast, Videos, Libros
  String _selectedFilter = 'Todo';

  // Texto del buscador de la seccion. Filtra en local sobre lo ya descargado:
  // la pantalla carga todo el contenido de golpe para poder filtrar por tipo,
  // asi que buscar no necesita volver a la red.
  final TextEditingController _buscadorController = TextEditingController();
  String _consulta = '';

  @override
  void initState() {
    super.initState();
    _fetchInitialPosts();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _fetchInitialPosts() async {
    if (_disposed) return;
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch all content items across categories to have a complete set to filter locally
      final results = await Future.wait([
        _graphqlService.getPosts(first: 20),
        _customContentService.getCustomContents(),
        // Tercera fuente desde el 2026-08-18: los canales de YouTube de Legacy
        // Network y LSO. Antes la sección solo tenía los videos que alguien
        // hubiera cargado a mano, y había exactamente uno.
        _videoCanalService.getVideos(),
      ]);

      // Verificar que el widget siga montado antes de continuar con setState
      if (_disposed || !mounted) return;

      final wpResponse = results[0] as GraphqlPostsResponse;
      final localResponse = results[1] as List<CustomContent>;
      final videosDeCanal = results[2] as List<VideoDeCanal>;

      // Unify results converting all to ContentItem
      final List<ContentItem> unified = [
        ...localResponse.map((c) => c.toContentItem()),
        ...videosDeCanal.map((v) => v.toContentItem()),
        ...wpResponse.posts.map((p) => p.toContentItem()),
      ];


      setState(() {
        _posts = unified;
        _isLoading = false;
        _hasMore = wpResponse.hasNextPage;
        _endCursor = wpResponse.endCursor;
      });
    } catch (e) {
      // Solo mostrar error si el widget sigue activo
      if (_disposed || !mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar contenido: $e')),
      );
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _fetchMorePosts();
    }
  }

  Future<void> _fetchMorePosts() async {
    if (_disposed) return;
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final response = await _graphqlService.getPosts(
        first: 10,
        after: _endCursor,
      );
      // Verificar que el widget siga montado después de la operación async
      if (_disposed || !mounted) return;
      setState(() {
        _posts.addAll(response.posts.map((p) => p.toContentItem()));
        _isLoadingMore = false;
        _hasMore = response.hasNextPage;
        _endCursor = response.endCursor;
      });
    } catch (e) {
      if (_disposed || !mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter the items by selected tab filter
    List<ContentItem> filteredPosts = [];
    if (_selectedFilter == 'Todo') {
      filteredPosts = _posts;
    } else if (_selectedFilter == 'Artículos') {
      filteredPosts = _posts.where((post) => post.type.isEmpty || post.type == 'article').toList();
    } else if (_selectedFilter == 'Podcast') {
      filteredPosts = _posts.where((post) => post.type == 'podcast').toList();
    } else if (_selectedFilter == 'Videos') {
      filteredPosts = _posts.where((post) => post.type == 'video').toList();
    } else if (_selectedFilter == 'Libros') {
      filteredPosts = _posts.where((post) => post.type == 'book' || post.type == 'libros').toList();
    }

    // La busqueda se acumula sobre el filtro de tipo, no lo sustituye: con
    // "Videos" activo y "gobierno" escrito salen solo los videos de gobierno.
    // El criterio es el mismo del buscador global (sin tildes, por palabras
    // sueltas en cualquier orden), reutilizado desde busqueda_global.dart para
    // que las dos busquedas no se comporten distinto.
    if (_consulta.trim().isNotEmpty) {
      filteredPosts = filteredPosts
          .where((post) => coincide(
                '${post.title} ${post.description ?? ''} ${post.category}',
                _consulta,
              ))
          .toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050B15),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/chatbot'),
        backgroundColor: const Color(0xFF0B1A2E),
        shape: CircleBorder(
          side: BorderSide(
            color: const Color(0xFFD9A74A),
            width: 1.5,
          ),
        ),
        child: const Icon(
          Icons.headphones_outlined,
          color: Color(0xFFD9A74A),
          size: 24,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.8, -0.8),
            radius: 1.5,
            colors: [
              Color(0xFF13304A),
              Color(0xFF0E2C3B),
              Color(0xFF050B15),
            ],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom AppBar Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/home');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B1A2E),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF1E3A5F).withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Legacy Knowledge',
                            style: GoogleFonts.barlow(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Conocimiento aplicado • nuevo cada semana',
                            style: GoogleFonts.questrial(
                              fontSize: 13,
                              color: const Color(0xFF90A4BA),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Buscador de la seccion
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                child: TextField(
                  controller: _buscadorController,
                  onChanged: (valor) => setState(() => _consulta = valor),
                  textInputAction: TextInputAction.search,
                  style: GoogleFonts.questrial(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Buscar en Legacy Knowledge',
                    hintStyle: GoogleFonts.questrial(
                      color: const Color(0xFF90A4BA),
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF90A4BA),
                      size: 20,
                    ),
                    suffixIcon: _consulta.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Color(0xFF90A4BA),
                              size: 18,
                            ),
                            tooltip: 'Limpiar',
                            onPressed: () {
                              _buscadorController.clear();
                              setState(() => _consulta = '');
                            },
                          ),
                    filled: true,
                    fillColor: const Color(0xFF0B1A2E).withValues(alpha: 0.55),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: const Color(0xFF2A4A75).withValues(alpha: 0.35),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: const Color(0xFF2A4A75).withValues(alpha: 0.35),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD9A74A)),
                    ),
                  ),
                ),
              ),

              // Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildPillFilter('Todo'),
                      _buildPillFilter('Artículos'),
                      _buildPillFilter('Podcast'),
                      _buildPillFilter('Videos'),
                      _buildPillFilter('Libros'),
                    ],
                  ),
                ),
              ),

              // Content Area
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _fetchInitialPosts,
                        color: const Color(0xFFD9A74A),
                        backgroundColor: const Color(0xFF0B1A2E),
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Weekly Release Banner
                              _buildWeeklyBanner(),
                              const SizedBox(height: 24),

                              if (_selectedFilter == 'Todo') ...[
                                // ESTA SEMANA (Videos)
                                _buildSectionHeader('ESTA SEMANA'),
                                const SizedBox(height: 12),
                                ...filteredPosts
                                    .where((p) => p.type == 'video')
                                    .take(2)
                                    .map((post) => _buildPostRowItem(post)),
                                const SizedBox(height: 24),

                                // PODCAST LEGACY
                                _buildSectionHeader('PODCAST LEGACY'),
                                const SizedBox(height: 12),
                                ...filteredPosts
                                    .where((p) => p.type == 'podcast')
                                    .take(2)
                                    .map((post) => _buildPostRowItem(post)),
                                const SizedBox(height: 24),

                                // BIBLIOTECA EJECUTIVA
                                _buildSectionHeader('BIBLIOTECA EJECUTIVA'),
                                const SizedBox(height: 12),
                                ...filteredPosts
                                    .where((p) => p.type == 'book' || p.type == 'libros')
                                    .take(2)
                                    .map((post) => _buildPostRowItem(post)),
                                const SizedBox(height: 24),

                                // ARTÍCULOS E INVESTIGACIÓN
                                _buildSectionHeader('ARTÍCULOS E INVESTIGACIÓN'),
                                const SizedBox(height: 12),
                                ...filteredPosts
                                    .where((p) => p.type.isEmpty || p.type == 'article')
                                    .take(4)
                                    .map((post) => _buildPostRowItem(post)),
                              ] else ...[
                                // Filtered list layout
                                _buildSectionHeader(_selectedFilter.toUpperCase()),
                                const SizedBox(height: 12),
                                if (filteredPosts.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                                    child: Center(
                                      child: Text(
                                        // Con una busqueda escrita, el vacio no
                                        // significa que no haya contenido de
                                        // ese tipo, sino que nada coincide.
                                        _consulta.trim().isEmpty
                                            ? 'No hay contenido de este tipo actualmente.'
                                            : 'Nada coincide con "${_consulta.trim()}".',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.questrial(
                                          color: const Color(0xFF90A4BA),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  ...filteredPosts.map((post) => _buildPostRowItem(post)),
                              ],
                              if (_isLoadingMore)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16.0),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFD9A74A),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillFilter(String filterName) {
    final bool isSelected = _selectedFilter == filterName;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = filterName;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isSelected ? const Color(0xFFD9A74A) : const Color(0xFF0B1A2E).withValues(alpha: 0.4),
            border: Border.all(
              color: isSelected ? const Color(0xFFD9A74A) : Colors.white10,
              width: 1,
            ),
          ),
          child: Text(
            filterName,
            style: GoogleFonts.questrial(
              color: isSelected ? const Color(0xFF050B15) : const Color(0xFF90A4BA),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF132A44),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              color: Color(0xFFD9A74A),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estreno semanal',
                  style: GoogleFonts.barlow(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cada lunes publicamos contenido nuevo. Active notificaciones.',
                  style: GoogleFonts.questrial(
                    color: const Color(0xFF90A4BA),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.barlow(
        color: const Color(0xFFD9A74A),
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildPostRowItem(ContentItem post) {
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
          if (post.type == 'video') {
            context.push('/video-detail', extra: post);
          } else {
            context.push('/article-detail', extra: post);
          }
        },
        child: Row(
          children: [
            // Left icon container
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
                _getIconForType(post.type),
                color: const Color(0xFFD9A74A),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            // Center info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.barlow(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getSubtitleForPost(post),
                    style: GoogleFonts.questrial(
                      color: const Color(0xFF90A4BA),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Right badge
            _buildRightBadge(post),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Icons.play_arrow_outlined;
      case 'podcast':
        return Icons.mic_none_outlined;
      case 'book':
      case 'libros':
        return Icons.menu_book_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  String _getSubtitleForPost(ContentItem post) {
    switch (post.type.toLowerCase()) {
      case 'video':
        return 'Video • ${post.duration ?? '18 min'}';
      case 'podcast':
        return 'Podcast • Ep. ${post.views ?? '24'}';
      case 'book':
      case 'libros':
        return post.description ?? 'Resumen de libro';
      default:
        return 'Artículo • ${post.readTime ?? '6 min'}';
    }
  }

  Widget _buildRightBadge(ContentItem post) {
    if ((post.type.toLowerCase() == 'book' || post.type.toLowerCase() == 'libros') && post.isFree) {
      if (post.title.toLowerCase().contains('gonzalo')) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: const Color(0xFF5FF2DE).withValues(alpha: 0.5),
            ),
            color: const Color(0xFF0C2423),
          ),
          child: Text(
            'RESUMEN LIBRE',
            style: GoogleFonts.barlow(
              color: const Color(0xFF5FF2DE),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }
    }
    
    if (!post.isFree) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: const Color(0xFFD9A74A),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            'L',
            style: GoogleFonts.barlow(
              color: const Color(0xFF050B15),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFF00F2FE).withValues(alpha: 0.5),
        ),
        color: const Color(0xFF00F2FE).withValues(alpha: 0.05),
      ),
      child: Text(
        'GRATIS',
        style: GoogleFonts.barlow(
          color: const Color(0xFF00F2FE),
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Marcar como disposed antes de liberar recursos para cortar callbacks async en vuelo
    _disposed = true;
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _buscadorController.dispose();
    super.dispose();
  }
}
