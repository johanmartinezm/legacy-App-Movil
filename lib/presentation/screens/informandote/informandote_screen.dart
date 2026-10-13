import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../domain/models/graphql_post_model.dart';
import '../../../domain/models/content_model.dart';
import '../../../domain/models/book_model.dart';
import '../../../data/config/image_helper.dart';
import '../../../domain/models/custom_content_model.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_theme.dart';
import '../../../data/services/graphql_service.dart';
import '../../../data/services/custom_content_service.dart';
import '../../../data/services/video_canal_service.dart';
import '../../../domain/models/video_canal_model.dart';
import '../../../domain/utils/busqueda_global.dart';
import '../../../domain/utils/ultimo_estreno.dart';
import '../../widgets/boton_volver.dart';

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

  /// Los libros de la tienda de LSO, por id, para abrir su ficha al tocar la
  /// fila: la ficha necesita el libro entero, no la versión reducida.
  Map<String, GraphqlBook> _libros = const {};
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _endCursor;
  // Flag para prevenir setState() después de dispose()
  bool _disposed = false;
  
  // Selected filter matching: Todo, Artículos, Libros, Videos, Podcast
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
        // Cuarta fuente desde el 2026-10-13: los libros de la Biblioteca (la
        // tienda de LSO), que hasta entonces solo se veían en Programas y
        // dejaban vacío el filtro «Libros». Si la tienda falla, la sección
        // carga igual sin libros.
        _graphqlService.getBooks().catchError((_) => <GraphqlBook>[]),
      ]);

      // Verificar que el widget siga montado antes de continuar con setState
      if (_disposed || !mounted) return;

      final wpResponse = results[0] as GraphqlPostsResponse;
      final localResponse = results[1] as List<CustomContent>;
      final videosDeCanal = results[2] as List<VideoDeCanal>;
      final libros = results[3] as List<GraphqlBook>;

      // Unify results converting all to ContentItem
      final List<ContentItem> unified = [
        ...localResponse.map((c) => c.toContentItem()),
        ...videosDeCanal.map((v) => v.toContentItem()),
        ...wpResponse.posts.map((p) => p.toContentItem()),
        ...libros.map(_libroComoContenido),
      ];


      setState(() {
        _posts = unified;
        _libros = {for (final l in libros) l.id: l};
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
      backgroundColor: const Color(0xFF162540),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/chatbot'),
        backgroundColor: const Color(0xFF1B3156),
        shape: CircleBorder(
          side: BorderSide(
            color: AppTheme.legacyActive,
            width: 1.5,
          ),
        ),
        child: const Icon(
          Icons.psychology_outlined,
          color: AppTheme.legacyActive,
          size: 24,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.8, -0.8),
            radius: 1.5,
            colors: [
              Color(0xFF183D6B),
              Color(0xFF183D6B),
              Color(0xFF162540),
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
                    const BotonVolver(),
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
                              color: const Color(0xFF9FB2C2),
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
                      color: const Color(0xFF9FB2C2),
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF9FB2C2),
                      size: 20,
                    ),
                    suffixIcon: _consulta.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Color(0xFF9FB2C2),
                              size: 18,
                            ),
                            tooltip: 'Limpiar',
                            onPressed: () {
                              _buscadorController.clear();
                              setState(() => _consulta = '');
                            },
                          ),
                    filled: true,
                    fillColor: const Color(0xFF1B3156).withValues(alpha: 0.55),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: const Color(0xFF306C9E).withValues(alpha: 0.35),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: const Color(0xFF306C9E).withValues(alpha: 0.35),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.legacyActive),
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
                      _buildPillFilter('Libros'),
                      _buildPillFilter('Videos'),
                      _buildPillFilter('Podcast'),
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
                        color: AppTheme.legacyActive,
                        backgroundColor: const Color(0xFF1B3156),
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
                                          color: const Color(0xFF9FB2C2),
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
                                      color: AppTheme.legacyActive,
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
            color: isSelected ? AppTheme.legacyActive : const Color(0xFF1B3156).withValues(alpha: 0.4),
            border: Border.all(
              color: isSelected ? AppTheme.legacyActive : Colors.white10,
              width: 1,
            ),
          ),
          child: Text(
            filterName,
            style: GoogleFonts.questrial(
              color: isSelected ? const Color(0xFF162540) : const Color(0xFF9FB2C2),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  /// Abre el detalle que corresponde al tipo: lo comparten las filas y el
  /// banner del estreno.
  void _abrirContenido(ContentItem post) {
    final libro = _libros[post.id];
    if (post.type == 'book' && libro != null) {
      context.push('/book-detail', extra: libro);
    } else if (post.type == 'video') {
      context.push('/video-detail', extra: post);
    } else {
      context.push('/article-detail', extra: post);
    }
  }

  /// Banner «Estreno semanal»: el contenido más reciente, que se abre al
  /// tocarlo. Mientras carga, o si nada trae fecha, queda el aviso de siempre.
  Widget _buildWeeklyBanner() {
    final estreno = ultimoEstreno(_posts);

    final decoracion = BoxDecoration(
      color: const Color(0xFF1B3156).withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: const Color(0xFF306C9E).withValues(alpha: 0.35),
        width: 1.2,
      ),
    );

    final etiqueta = Text(
      'ESTRENO SEMANAL',
      style: GoogleFonts.barlow(
        color: AppTheme.legacyActive,
        fontWeight: FontWeight.bold,
        fontSize: 11,
        letterSpacing: 1.2,
      ),
    );

    if (estreno == null) {
      return Container(
        key: const Key('estreno-semanal-fijo'),
        padding: const EdgeInsets.all(16),
        decoration: decoracion,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1B3156),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                color: AppTheme.legacyActive,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  etiqueta,
                  const SizedBox(height: 4),
                  Text(
                    'Cada lunes publicamos contenido nuevo.',
                    style: GoogleFonts.questrial(
                      color: const Color(0xFF9FB2C2),
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

    final fecha = fechaCortaEstreno(estreno.date);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('estreno-semanal'),
        borderRadius: BorderRadius.circular(12),
        onTap: () => _abrirContenido(estreno),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: decoracion,
          child: Row(
            children: [
              _buildMiniatura(estreno),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    etiqueta,
                    const SizedBox(height: 4),
                    Text(
                      estreno.title,
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
                      [tipoEstreno(estreno), if (fecha.isNotEmpty) fecha].join(' · '),
                      style: GoogleFonts.questrial(
                        color: const Color(0xFF9FB2C2),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppTheme.legacyActive, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.barlow(
        color: AppTheme.legacyActive,
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
        color: const Color(0xFF1B3156).withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF306C9E).withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: InkWell(
        onTap: () => _abrirContenido(post),
        child: Row(
          children: [
            _buildMiniatura(post),
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
                      color: const Color(0xFF9FB2C2),
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

  /// Un libro de la tienda de LSO como fila de Legacy Knowledge, en la
  /// categoría «Libros». Sin precio, igual que en la cuadrícula de la Biblioteca.
  ContentItem _libroComoContenido(GraphqlBook libro) => ContentItem(
        id: libro.id,
        title: libro.name,
        type: 'book',
        category: 'Libros',
        isFree: false,
        imageUrl: ImageHelper.getProxiedImageUrl(libro.imageUrl ?? ''),
        description: libro.stockStatus == 'OUT_OF_STOCK'
            ? 'Libro · Agotado'
            : 'Libro · Tienda LSO',
        externalUrl: libro.url,
      );

  // Videos y articulos llevan su imagen (miniatura del video, imagen
  // destacada del articulo); sin imagen, o si no carga, el icono del tipo.
  Widget _buildMiniatura(ContentItem post) {
    final icono = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF1B3156),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF183D6B).withValues(alpha: 0.4),
        ),
      ),
      child: Icon(
        _getIconForType(post.type),
        color: AppTheme.legacyActive,
        size: 20,
      ),
    );

    final tipo = post.type.toLowerCase();
    final esLibro = tipo == 'book' || tipo == 'libros';
    final conImagen = tipo == 'video' || tipo == 'article' || esLibro;
    if (!conImagen || post.imageUrl.trim().isEmpty) return icono;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        // Los libros, en vertical como su portada.
        width: esLibro ? 44 : 80,
        height: esLibro ? 62 : 56,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: post.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: const Color(0xFF1B3156)),
              errorWidget: (_, __, ___) => Center(child: icono),
            ),
            if (tipo == 'video')
              const Center(
                child: CircleAvatar(
                  radius: 13,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.play_arrow, color: Colors.white, size: 18),
                ),
              ),
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
    // Los libros de la tienda de LSO no llevan insignia ni precio: se venden
    // allí, y la ficha que abre la fila lo explica.
    if (_libros.containsKey(post.id)) {
      return const Icon(Icons.chevron_right, color: AppTheme.legacyActive, size: 22);
    }
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
          color: AppTheme.legacyActive,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            'L',
            style: GoogleFonts.barlow(
              color: const Color(0xFF162540),
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
