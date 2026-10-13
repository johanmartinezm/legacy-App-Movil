import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/notification_provider.dart';
import '../../../data/services/busqueda_service.dart';
import '../../../domain/models/resultado_busqueda.dart';
import '../../../domain/providers/chat_provider.dart';
import '../../delegates/global_search_delegate.dart';
import 'package:legacy_app/presentation/widgets/common/legacy_logo.dart';
import '../../../data/services/secciones_inicio_service.dart';
import 'widgets/fondo_con_imagen.dart';
import 'package:legacy_app/config/theme/app_theme.dart';

class HomeContentScreen extends StatefulWidget {
  /// Se inyecta en las pruebas; en la app se crea el de verdad.
  final SeccionesInicioService? seccionesService;

  const HomeContentScreen({super.key, this.seccionesService});

  @override
  State<HomeContentScreen> createState() => _HomeContentScreenState();
}

class _HomeContentScreenState extends State<HomeContentScreen> {
  /// `slug → SeccionInicio` de las tarjetas con imagen, título o texto
  /// cambiados desde el panel (Tarjetas del Inicio). Vacío hasta que responde
  /// el backend, y también si falla: entonces cada tarjeta se pinta como
  /// siempre, con su icono y sus textos de la app.
  Map<String, SeccionInicio> _secciones = const {};

  @override
  void initState() {
    super.initState();
    _cargarImagenes();
  }

  Future<void> _cargarImagenes() async {
    final secciones =
        await (widget.seccionesService ?? SeccionesInicioService()).secciones();
    if (mounted && secciones.isNotEmpty) setState(() => _secciones = secciones);
  }

  /// Envuelve el contenido de una tarjeta. Con imagen, la foto de fondo con su
  /// capa oscura; sin ella, la decoración de siempre. El borde se conserva en
  /// los dos casos para que la tarjeta no cambie de silueta.
  Widget _tarjeta({
    required String slug,
    required BoxDecoration decoracion,
    required EdgeInsetsGeometry padding,
    required Widget child,
    Alignment oscuroHacia = Alignment.bottomCenter,
    EdgeInsetsGeometry? margin,
    double? width,
  }) {
    final url = _secciones[slug]?.imagenUrl;
    final radio =
        (decoracion.borderRadius as BorderRadius?) ?? BorderRadius.zero;
    if (url == null) {
      return Container(
        key: Key('tarjeta-$slug'),
        width: width,
        margin: margin,
        padding: padding,
        decoration: decoracion,
        child: child,
      );
    }
    return Container(
      key: Key('tarjeta-$slug-con-imagen'),
      width: width,
      margin: margin,
      foregroundDecoration: BoxDecoration(
        borderRadius: radio,
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: FondoConImagen(
        imagenUrl: url,
        borderRadius: radio,
        padding: padding,
        oscuroHacia: oscuroHacia,
        // Filas horizontales (Nuevo cada semana, Beneficios, Miembros): capa
        // más oscura en todo el ancho para que se lea el subtítulo y la flecha.
        opacidadLadoClaro: oscuroHacia.y == 0 ? 0.6 : 0.15,
        child: child,
      ),
    );
  }

  bool _conImagen(String slug) => _secciones[slug]?.imagenUrl != null;

  /// Título y texto de la tarjeta: los del panel si los hay, si no los de
  /// siempre, que se pasan como `porDefecto`.
  String _titulo(String slug, String porDefecto) =>
      _secciones[slug]?.titulo ?? porDefecto;

  String _texto(String slug, String porDefecto) =>
      _secciones[slug]?.texto ?? porDefecto;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final String name = authProvider.firstName ?? 'Usuario';
    final String role = authProvider.role ?? '';

    String greetSub = 'Su legado avanza.';
    if (role == 'empresa') {
      greetSub = 'Su gobierno madura.';
    } else if (role == 'junta') {
      greetSub = 'Su perfil de gobierno crece.';
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.8, -0.8),
            radius: 1.5,
            colors: [Color(0xFF183D6B), Color(0xFF183D6B), Color(0xFF162540)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildCustomHeader(context),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildGreetingSection(name, greetSub),
                          const SizedBox(height: 20),
                          _buildWeeklyHighlightCard(context, role),
                          const SizedBox(height: 28),
                          _buildExploreHeader(context),
                          const SizedBox(height: 16),
                          _buildExploreGrid(context),
                          const SizedBox(height: 28),
                          _buildServicesHeader(context),
                          const SizedBox(height: 12),
                          _buildPremiumRows(context),
                          const SizedBox(height: 28),
                          _buildLegacyTestHero(context),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(bottom: 20, right: 20, child: _buildChatFAB(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: LegacyLogo(height: 32),
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white, size: 22),
                onPressed: _handleSearch,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 16),
              Consumer<NotificationProvider>(
                builder: (context, notificationProvider, child) {
                  final unreadCount = notificationProvider.unreadCount;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_none,
                          color: Colors.white,
                          size: 22,
                        ),
                        onPressed: () => context.push('/notifications'),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF70ABE0),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF162540),
                                width: 1.5,
                              ),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 14,
                              minHeight: 14,
                            ),
                            child: Center(
                              child: Text(
                                '$unreadCount',
                                style: GoogleFonts.barlow(
                                  color: const Color(0xFF1B3156),
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => context.go('/profile'),
                child: Container(
                  width: 29,
                  height: 29,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF8AC6FB),
                      width: 1.5,
                    ),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF306C9E), Color(0xFF183D6B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleSearch() async {
    // Se toma antes de cualquier await: después el context puede haber dejado
    // de ser válido.
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    bool isDialogActive = false;
    BuildContext? dialogContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dCtx) {
        dialogContext = dCtx;
        return const Center(child: CircularProgressIndicator());
      },
    );
    isDialogActive = true;
    try {
      await Future.delayed(const Duration(milliseconds: 100));

      // Los miembros ya están en memoria si el chat se abrió alguna vez; si no,
      // se piden ahora. Es la única fuente que necesita sesión.
      if (chatProvider.members.isEmpty) {
        try {
          await chatProvider.loadMembers();
        } catch (_) {
          // Buscar sin miembros es mejor que no buscar.
        }
      }

      final todo = await BusquedaService().cargarTodo(
        miembros: chatProvider.members,
      );

      if (dialogContext != null && dialogContext!.mounted && isDialogActive) {
        Navigator.of(dialogContext!).pop();
        isDialogActive = false;
      }
      await Future.delayed(Duration.zero);

      if (mounted) {
        await showSearch<ResultadoBusqueda?>(
          context: context,
          delegate: GlobalSearchDelegate(todo: todo),
        );
      }
    } catch (e) {
      if (dialogContext != null && dialogContext!.mounted && isDialogActive) {
        Navigator.of(dialogContext!).pop();
        isDialogActive = false;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo preparar la búsqueda: $e')),
        );
      }
    }
  }

  Widget _buildGreetingSection(String name, String sub) {
    final hour = DateTime.now().hour;
    String greeting = 'Buenos días,';
    if (hour >= 12 && hour < 19) {
      greeting = 'Buenas tardes,';
    } else if (hour >= 19) {
      greeting = 'Buenas noches,';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: GoogleFonts.questrial(
            color: const Color(0xFF9FB2C2),
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: GoogleFonts.barlow(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
            children: [
              TextSpan(
                text: '$name. ',
                style: const TextStyle(color: Colors.white),
              ),
              TextSpan(
                text: sub,
                style: const TextStyle(color: Color(0xFF8AC6FB)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Antes de esto se pedía el último post por GraphQL y se mostraba su
  // título completo, con el toque llevando directo a ese artículo puntual.
  // Decisión del cliente (revisión de Diana Uribe, 22-08-2026): la tarjeta
  // debe anunciar que hay novedades sin agotar el contenido ahí mismo, y
  // llevar a la sección de Legacy Knowledge, no a un artículo en concreto —
  // «Esta semana» puede traer un artículo, un video o un evento nuevo, y la
  // tarjeta no distingue cuál fue.
  Widget _buildWeeklyHighlightCard(BuildContext context, String role) {
    String subtitle;
    if (role == 'junta') {
      subtitle =
          'Esta semana: masterclass del consejero independiente, nuevo evento...';
    } else if (role == 'empresa') {
      subtitle =
          'Esta semana: caso de junta ceremonial, masterclass de gobierno...';
    } else {
      subtitle =
          'Esta semana: video de conversaciones difíciles, evento familiar...';
    }

    const slug = 'nuevo-cada-semana';
    final conImagen = _conImagen(slug);
    return GestureDetector(
      onTap: () => context.go('/informandote'),
      child: _tarjeta(
        slug: slug,
        oscuroHacia: Alignment.centerLeft,
        padding: const EdgeInsets.all(16),
        decoracion: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF70ABE0).withValues(alpha: 0.08),
              Colors.transparent,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF70ABE0).withValues(alpha: 0.25),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            if (!conImagen) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF70ABE0).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  color: Color(0xFF8AC6FB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _titulo(slug, 'Nuevo cada semana'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.barlowCondensed(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _texto(slug, subtitle),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.questrial(
                      color: conImagen
                          ? const Color(0xFFCFE0F0)
                          : const Color(0xFF9FB2C2),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFF8AC6FB), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Explore libremente',
          style: GoogleFonts.barlowCondensed(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        GestureDetector(
          onTap: () => context.go('/informandote'),
          child: Text(
            'Ver todo',
            style: GoogleFonts.questrial(
              color: const Color(0xFF8AC6FB),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExploreGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.95,
      children: [
        _buildModuleCard(
          context: context,
          // "Legacy Knowledge" es el nombre oficial de la sección desde el
          // 2026-08-18. Antes el home decía "Contenido de valor" y la sección
          // se presentaba como Legacy Knowledge, y el cliente lo reportó.
          slug: 'legacy-knowledge',
          title: 'Legacy Knowledge',
          subtitle: 'Artículos, podcast, videos y libros',
          icon: Icons.menu_book,
          iconColor: const Color(0xFF8AC6FB),
          onTap: () => context.go('/informandote'),
        ),
        _buildModuleCard(
          context: context,
          slug: 'eventos',
          title: 'Eventos',
          subtitle: 'Masterclass virtual en vivo y Legacy Summit presencial',
          icon: Icons.calendar_month,
          iconColor: const Color(0xFF54C6A8),
          onTap: () => context.go('/home?tab=1'),
        ),
        _buildModuleCard(
          context: context,
          slug: 'lso-escuela',
          title: 'LSO · Escuela',
          subtitle: 'Programas de formación',
          icon: Icons.school,
          iconColor: const Color(0xFF70ABE0),
          onTap: () => context.push('/programas'),
        ),
        _buildModuleCard(
          context: context,
          slug: 'asesorias',
          title: 'Asesorías',
          subtitle: 'L&M · Aurum · Legacy Legal',
          icon: Icons.show_chart,
          iconColor: const Color(0xFFB3A6EE),
          onTap: () => context.push('/asesoria'),
        ),
        // La tarjeta «Beneficios» de la cuadrícula se retiró el 2026-10-13 a
        // pedido del cliente; queda la fila del mismo nombre en Servicios
        // Legacy, que usa la misma imagen y textos del panel.
        // «Legacy+» también se retiró de la cuadrícula el 2026-10-13: se llega
        // desde la barra inferior y desde «Cómo accedo» de la sección Legacy+.
        // Penúltimo del grid desde el 2026-10-13, a pedido del cliente, justo
        // antes de Contáctenos (antes fue el primero, decisión del 2026-09-02). El contenido de esta
        // pantalla lo edita el panel, no viaja en la app: por eso es una ruta
        // propia y no el diálogo que sigue viviendo en Comunidad.
        _buildModuleCard(
          context: context,
          slug: 'legacy-board',
          title: 'Legacy Board',
          subtitle: 'Gobierno corporativo para familias empresarias',
          icon: Icons.dashboard,
          iconColor: AppTheme.legacyActive,
          onTap: () => context.push('/legacy-board'),
        ),
        // Contáctenos cierra la cuadrícula desde el 2026-10-13.
        // push y no go: desde aquí se entra a escribir y se vuelve, así que la
        // pantalla se apila en vez de sustituir a la sección actual.
        _buildModuleCard(
          context: context,
          slug: 'contactenos',
          title: 'Contáctenos',
          subtitle: 'Escríbenos si necesitas ayuda',
          icon: Icons.support_agent,
          iconColor: const Color(0xFF54C6A8),
          onTap: () => context.push('/contacto'),
        ),
      ],
    );
  }

  Widget _buildModuleCard({
    required BuildContext context,
    required String slug,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final conImagen = _conImagen(slug);
    return GestureDetector(
      onTap: onTap,
      child: _tarjeta(
        slug: slug,
        padding: const EdgeInsets.all(14),
        decoracion: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.025),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Con foto, el icono sobra: la imagen ya identifica la tarjeta.
            if (!conImagen)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            const Spacer(),
            Text(
              _titulo(slug, title),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.barlowCondensed(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _texto(slug, subtitle),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.questrial(
                color: conImagen
                    ? const Color(0xFFCFE0F0)
                    : const Color(0xFF9FB2C2),
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Esta función estará disponible próximamente.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildServicesHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // «Legacy+» y no «Servicios Legacy» desde el 2026-10-13, a pedido del
        // cliente: la tarjeta Legacy+ salió de la cuadrícula y la sección
        // toma su nombre.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Legacy+',
                style: GoogleFonts.barlowCondensed(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Servicios y beneficios plus para los clientes de Legacy Network o Alumni LSO',
                style: GoogleFonts.questrial(
                  color: const Color(0xFF9FB2C2),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => context.go('/legacy-plus'),
          child: Text(
            'Cómo accedo',
            style: GoogleFonts.questrial(
              color: const Color(0xFF8AC6FB),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumRows(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isCliente = authProvider.customerStatus == 'Ya soy cliente';

    // Orden y textos del cliente, 2026-10-13: Chats de sinergia, Legacy Board
    // (la fila que era «Miembros», con el mismo destino) y Beneficios.
    return Column(
      children: [
        // «Chats de sinergia»: abre los foros anónimos que ya existían (se
        // llegaba solo desde Perfil), con el mismo candado que Miembros. Ese
        // mismo día se llamó «Foro» unas horas.
        _filaExclusiva(
          context,
          isCliente: isCliente,
          slug: 'chats-sinergia',
          titulo: 'Chats de sinergia',
          texto: 'Chats de sinergia entre pares: hay 4 chats para hablar de temas de Empresa, Patrimonio, Familia y otros entre miembros de otras familias empresarias.',
          icono: Icons.forum_outlined,
          ruta: '/forums',
        ),
        // Era «Miembros · Comunidad del ecosistema Legacy»; el cliente le cambió
        // el título y el texto. Bloqueada para todos «por el momento»
        // (2026-10-13): el destino, /miembros-info, se conserva para cuando se
        // abra. El slug del panel sigue siendo `miembros`.
        _filaExclusiva(
          context,
          isCliente: isCliente,
          bloqueada: true,
          slug: 'miembros',
          titulo: 'Legacy Board',
          texto: 'Red de gobierno corporativo que conecta a familias empresarias y empresas que necesitan crear o fortalecer sus órganos de gobierno (juntas directivas, consejos de familia, directorios, advisory boards y comités) con profesionales que quieren servir en ellos.',
          icono: Icons.dashboard_outlined,
          ruta: '/miembros-info',
          margin: const EdgeInsets.only(top: 8),
        ),
        // Bloqueada: tocarla no hace nada ni muestra aviso (2026-10-13).
        GestureDetector(
          // Última de la sección desde el 2026-10-13. La tarjeta Beneficios de
          // la cuadrícula se retiró ese día; esta fila es la que queda.
          child: _tarjeta(
            slug: 'beneficios',
            oscuroHacia: Alignment.centerLeft,
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(14),
            decoracion: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                if (!_conImagen('beneficios')) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      color: Colors.white.withValues(alpha: 0.3),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _titulo('beneficios', 'Beneficios'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.barlowCondensed(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _texto(
                          'beneficios',
                          'Son descuentos y servicios especiales de aliados o de Legacy Network.',
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.questrial(
                          color: const Color(0xFF9FB2C2).withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.lock_outline,
                  color: Colors.white.withValues(alpha: 0.2),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Fila de la sección Legacy+ reservada a clientes («Ya soy cliente»): con
  /// candado y apagada para el resto. `bloqueada` la cierra también a los
  /// clientes. Una fila cerrada no hace nada al tocarla, sin aviso: así lo pidió
  /// el cliente el 2026-10-13. La usan Chats de sinergia y Legacy Board.
  Widget _filaExclusiva(
    BuildContext context, {
    required bool isCliente,
    required String slug,
    required String titulo,
    required String texto,
    required IconData icono,
    required String ruta,
    bool bloqueada = false,
    EdgeInsetsGeometry? margin,
  }) {
    // A partir de aquí «abierta» decide todo: el destino, el color y el candado.
    final abierta = isCliente && !bloqueada;
    return GestureDetector(
      onTap: abierta ? () => context.push(ruta) : null,
      child: _tarjeta(
        slug: slug,
        oscuroHacia: Alignment.centerLeft,
        margin: margin,
        padding: const EdgeInsets.all(14),
        decoracion: BoxDecoration(
          gradient: LinearGradient(
            colors: abierta
                ? [
                    const Color(0xFF54C6A8).withValues(alpha: 0.06),
                    const Color(0xFF54C6A8).withValues(alpha: 0.02),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.02),
                    Colors.white.withValues(alpha: 0.01),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: abierta
                ? const Color(0xFF54C6A8).withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            if (!_conImagen(slug)) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: abierta
                      ? const Color(0xFF54C6A8).withValues(alpha: 0.13)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icono,
                  color: abierta
                      ? const Color(0xFF54C6A8)
                      : Colors.white.withValues(alpha: 0.3),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _titulo(slug, titulo),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.barlowCondensed(
                      color: abierta
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _texto(slug, texto),
                    // Los textos de esta sección son de varias líneas (el de
                    // Legacy Board, unas cinco en un teléfono).
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.questrial(
                      color: abierta
                          ? const Color(0xFF9FB2C2)
                          : const Color(0xFF9FB2C2).withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (!abierta)
              Icon(
                Icons.lock_outline,
                color: Colors.white.withValues(alpha: 0.2),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegacyTestHero(BuildContext context) {
    return GestureDetector(
      onTap: () => _showComingSoon(context),
      child: _tarjeta(
        slug: 'legacy-test',
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoracion: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8AC6FB), Color(0xFF1B3156), Color(0xFF162540)],
            stops: [-0.2, 0.4, 1.0],
          ),
          border: Border.all(
            color: const Color(0xFF8AC6FB).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF8AC6FB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'PRÓXIMAMENTE',
                  style: GoogleFonts.barlow(
                    color: const Color(0xFF162540),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _titulo(
                'legacy-test',
                'Descubra las trampas de su familia empresaria',
              ),
              style: GoogleFonts.barlowCondensed(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _texto(
                'legacy-test',
                'Conteste gratis el diagnóstico del Modelo DINASTÍA. ¿Quiere profundizar? Conozca los niveles del Legacy Test.',
              ),
              style: GoogleFonts.questrial(
                color: const Color(0xFFCFE0F0),
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF8AC6FB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Conocer el Legacy Test',
                    style: GoogleFonts.barlow(
                      color: const Color(0xFF162540),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF162540),
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatFAB(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/chatbot'),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            center: Alignment(-0.3, -0.4),
            radius: 1.0,
            colors: [Color(0xFF306C9E), Color(0xFF1B3156)],
          ),
          border: Border.all(color: const Color(0xFF70ABE0), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 30,
              offset: const Offset(0, 10),
              spreadRadius: -8,
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.psychology_outlined,
            color: Color(0xFF8AC6FB),
            size: 25,
          ),
        ),
      ),
    );
  }
}
