import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/notification_provider.dart';
import '../../../data/services/graphql_service.dart';
import '../../../data/services/custom_content_service.dart';
import '../../../domain/models/content_model.dart';
import '../../../domain/models/graphql_post_model.dart';
import '../../../domain/models/custom_content_model.dart';
import '../../delegates/content_search_delegate.dart';

class HomeContentScreen extends StatefulWidget {
  const HomeContentScreen({super.key});

  @override
  State<HomeContentScreen> createState() => _HomeContentScreenState();
}

class _HomeContentScreenState extends State<HomeContentScreen> {
  late Future<GraphqlPostsResponse> _latestPostFuture;

  @override
  void initState() {
    super.initState();
    _latestPostFuture = GraphqlService().getPosts(first: 1);
  }

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
            colors: [
              Color(0xFF13304A),
              Color(0xFF0E2C3B),
              Color(0xFF050B15),
            ],
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
              Positioned(
                bottom: 20,
                right: 20,
                child: _buildChatFAB(context),
              ),
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
          Image.asset(
            'assets/images/Logo.png',
            height: 24,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'LEGACY NETWORK',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.barlow(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.5,
              ),
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
                        icon: const Icon(Icons.notifications_none, color: Colors.white, size: 22),
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
                              color: const Color(0xFF5A93C4),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF050B15), width: 1.5),
                            ),
                            constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                            child: Center(
                              child: Text(
                                '$unreadCount',
                                style: GoogleFonts.barlow(
                                  color: const Color(0xFF0B1A2E),
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
                    border: Border.all(color: const Color(0xFF7FB2D9), width: 1.5),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2A5D7D), Color(0xFF123A4F)],
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
      final graphqlService = GraphqlService();
      final customContentService = CustomContentService();
      final results = await Future.wait([
        graphqlService.getPosts(first: 50),
        customContentService.getCustomContents(),
      ]);
      if (dialogContext != null && dialogContext!.mounted && isDialogActive) {
        Navigator.of(dialogContext!).pop();
        isDialogActive = false;
      }
      await Future.delayed(Duration.zero);
      final wpResponse = results[0] as GraphqlPostsResponse;
      final localResponse = results[1] as List<CustomContent>;
      final List<ContentItem> unified = [
        ...localResponse.map((c) => c.toContentItem()),
        ...wpResponse.posts.map((p) => p.toContentItem()),
      ];
      if (mounted) {
        await showSearch<ContentItem?>(
          context: context,
          delegate: ContentSearchDelegate(allPosts: unified),
        );
      }
    } catch (e) {
      if (dialogContext != null && dialogContext!.mounted && isDialogActive) {
        Navigator.of(dialogContext!).pop();
        isDialogActive = false;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar contenido para buscar: $e')),
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
              TextSpan(text: '$name. ', style: const TextStyle(color: Colors.white)),
              TextSpan(text: sub, style: const TextStyle(color: Color(0xFF7FB2D9))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyHighlightCard(BuildContext context, String role) {
    return FutureBuilder<GraphqlPostsResponse>(
      future: _latestPostFuture,
      builder: (context, snapshot) {
        String subtitle = '';
        if (role == 'junta') {
          subtitle = 'Esta semana: masterclass del consejero independiente, nuevo evento...';
        } else if (role == 'empresa') {
          subtitle = 'Esta semana: caso de junta ceremonial, webinar de gobierno...';
        } else {
          subtitle = 'Esta semana: video de conversaciones difíciles, evento familiar...';
        }

        ContentItem? targetItem;
        if (snapshot.hasData && snapshot.data!.posts.isNotEmpty) {
          final post = snapshot.data!.posts.first;
          subtitle = 'Esta semana: ${post.title}';
          targetItem = post.toContentItem();
        }

        return GestureDetector(
          onTap: () {
            if (targetItem != null) {
              if (targetItem.type == 'video') {
                context.push('/video-detail', extra: targetItem);
              } else {
                context.push('/article-detail', extra: targetItem);
              }
            } else {
              context.go('/informandote');
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF5A93C4).withValues(alpha: 0.08), Colors.transparent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF5A93C4).withValues(alpha: 0.25),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5A93C4).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_month_outlined, color: Color(0xFF7FB2D9), size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nuevo cada semana',
                        style: GoogleFonts.barlowCondensed(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.questrial(color: const Color(0xFF9FB2C2), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Color(0xFF7FB2D9), size: 20),
              ],
            ),
          ),
        );
      },
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
              color: const Color(0xFF7FB2D9),
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
          title: 'Contenido de valor',
          subtitle: 'Artículos, podcast, videos y libros',
          icon: Icons.menu_book,
          iconColor: const Color(0xFF7FB2D9),
          onTap: () => context.go('/informandote'),
        ),
        _buildModuleCard(
          context: context,
          title: 'Eventos',
          subtitle: 'Webinars y Legacy Summit 2026',
          icon: Icons.calendar_month,
          iconColor: const Color(0xFF54C6A8),
          onTap: () => context.go('/home?tab=1'),
        ),
        _buildModuleCard(
          context: context,
          title: 'LSO · Escuela',
          subtitle: 'Programas de formación',
          icon: Icons.school,
          iconColor: const Color(0xFF5A93C4),
          onTap: () => context.go('/programas'),
        ),
        _buildModuleCard(
          context: context,
          title: 'Asesorías',
          subtitle: 'L&M · Aurum · Legacy Legal',
          icon: Icons.show_chart,
          iconColor: const Color(0xFFB3A6EE),
          onTap: () => context.go('/asesoria'),
        ),
        _buildModuleCard(
          context: context,
          title: 'Beneficios',
          subtitle: 'Próximamente',
          icon: Icons.shield_outlined,
          iconColor: const Color(0xFF7FB2D9).withValues(alpha: 0.5),
          onTap: () => _showComingSoon(context),
        ),
        _buildModuleCard(
          context: context,
          title: 'Legacy+',
          subtitle: 'Cómo accedo',
          icon: Icons.my_location,
          iconColor: const Color(0xFF5A93C4),
          onTap: () => context.go('/legacy-plus'),
        ),
        // push y no go: desde aquí se entra a escribir y se vuelve, así que la
        // pantalla se apila en vez de sustituir a la sección actual.
        _buildModuleCard(
          context: context,
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
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
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
              title,
              style: GoogleFonts.barlowCondensed(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.questrial(
                color: const Color(0xFF9FB2C2),
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
        Text(
          'Servicios Legacy',
          style: GoogleFonts.barlowCondensed(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        GestureDetector(
          onTap: () => context.go('/legacy-plus'),
          child: Text(
            'Cómo accedo',
            style: GoogleFonts.questrial(
              color: const Color(0xFF7FB2D9),
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

    return Column(
      children: [
        GestureDetector(
          onTap: () => _showComingSoon(context),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(Icons.shield_outlined, color: Colors.white.withValues(alpha: 0.3), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Beneficios', style: GoogleFonts.barlowCondensed(color: Colors.white.withValues(alpha: 0.5), fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('Próximamente', style: GoogleFonts.questrial(color: const Color(0xFF9FB2C2).withValues(alpha: 0.5), fontSize: 11)),
                    ],
                  ),
                ),
                Icon(Icons.lock_outline, color: Colors.white.withValues(alpha: 0.2), size: 20),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            if (isCliente) {
              context.push('/miembros-info');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Esta sección es exclusiva para clientes Legacy.')),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isCliente 
                  ? [const Color(0xFF54C6A8).withValues(alpha: 0.06), const Color(0xFF54C6A8).withValues(alpha: 0.02)]
                  : [Colors.white.withValues(alpha: 0.02), Colors.white.withValues(alpha: 0.01)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: isCliente ? const Color(0xFF54C6A8).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isCliente ? const Color(0xFF54C6A8).withValues(alpha: 0.13) : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(Icons.people_alt_outlined, color: isCliente ? const Color(0xFF54C6A8) : Colors.white.withValues(alpha: 0.3), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Miembros', style: GoogleFonts.barlowCondensed(color: isCliente ? Colors.white : Colors.white.withValues(alpha: 0.5), fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('Comunidad del ecosistema Legacy', style: GoogleFonts.questrial(color: isCliente ? const Color(0xFF9FB2C2) : const Color(0xFF9FB2C2).withValues(alpha: 0.5), fontSize: 11)),
                    ],
                  ),
                ),
                if (!isCliente)
                  Icon(Icons.lock_outline, color: Colors.white.withValues(alpha: 0.2), size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegacyTestHero(BuildContext context) {
    return GestureDetector(
      onTap: () => _showComingSoon(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7FB2D9), Color(0xFF1A2B4D), Color(0xFF0E1830)],
            stops: [-0.2, 0.4, 1.0],
          ),
          border: Border.all(color: const Color(0xFF7FB2D9).withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF7FB2D9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'PRÓXIMAMENTE',
                  style: GoogleFonts.barlow(
                    color: const Color(0xFF06223A),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Descubra las trampas de su familia empresaria',
              style: GoogleFonts.barlowCondensed(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Conteste gratis el diagnóstico del Modelo DINASTÍA. ¿Quiere profundizar? Conozca los niveles del Legacy Test.',
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
                color: const Color(0xFF7FB2D9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Conocer el Legacy Test',
                    style: GoogleFonts.barlow(
                      color: const Color(0xFF06223A),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right, color: Color(0xFF06223A), size: 18),
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
      onTap: () => context.go('/chatbot'),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            center: Alignment(-0.3, -0.4),
            radius: 1.0,
            colors: [Color(0xFF3A6F93), Color(0xFF0E2038)],
          ),
          border: Border.all(color: const Color(0xFF5A93C4), width: 1.0),
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
            color: Color(0xFF7FB2D9),
            size: 25,
          ),
        ),
      ),
    );
  }
}
