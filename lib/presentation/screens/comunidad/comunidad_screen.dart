import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../config/theme/app_theme.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/chat_provider.dart';
import '../../widgets/app_banner.dart';
import '../../widgets/custom_section_header.dart';

class ComunidadScreen extends StatefulWidget {
  const ComunidadScreen({super.key});

  @override
  State<ComunidadScreen> createState() => _ComunidadScreenState();
}

class _ComunidadScreenState extends State<ComunidadScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final chatProvider = context.read<ChatProvider>();
      chatProvider.loadConnections();
      chatProvider.connectWebSocket();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isRestricted = authProvider.customerStatus == 'Quiero ser cliente';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Global Header
            const CustomSectionHeader(title: 'COMUNIDAD'),

            Expanded(
              child: isRestricted
                  ? _buildRestrictedView(context)
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          // Top Banner header
                          const AppBanner(category: 'community'),

                          const SizedBox(height: 30),

                          // Grid of circular buttons
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                // Row 1
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildCircularButton(
                                      context,
                                      icon: Icons.handshake_outlined,
                                      label: 'Comité de\nSinergias',
                                      onTap: () {
                                        context.push('/comite-sinergias');
                                      },
                                    ),
                                    _buildCircularButton(
                                      context,
                                      icon: Icons.dashboard_outlined,
                                      label: 'Legacy\nBoard',
                                      // La página informativa de Legacy Board,
                                      // la misma del Inicio. Hasta el 2026-11-25
                                      // abría un diálogo con dos contactos fijos;
                                      // ahora, quien tiene el plus encuentra en
                                      // la página los botones a los formularios.
                                      onTap: () => context.push('/legacy-board'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 30),
                                // Row 2
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildCircularButton(
                                      context,
                                      icon: Icons.quiz_outlined,
                                      label: 'Legacy Test\nTrampas Familiares',
                                      onTap: () {
                                        // TODO: Implement action
                                      },
                                    ),
                                    Consumer<ChatProvider>(
                                      builder: (context, chatProvider, child) {
                                        return _buildCircularButton(
                                          context,
                                          icon: Icons.forum_outlined,
                                          label: 'Chat de los\nCEOs',
                                          badgeCount:
                                              chatProvider.totalUnreadCount,
                                          onTap: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Próximamente: El Chat de CEOs estará disponible pronto.'),
                                                duration: Duration(seconds: 3),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 160),

                          // Bottom Promo Banner (Footer)
                          _buildBottomPromoBanner(),

                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestrictedView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF183D6B).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_person_outlined,
                size: 80,
                color: Color(0xFF183D6B),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Espacio Exclusivo',
              textAlign: TextAlign.center,
              style: GoogleFonts.barlow(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF183D6B),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'Este espacio es exclusivo para miembros puede comunicarte con nosotros para obtener mas información.',
              textAlign: TextAlign.center,
              style: GoogleFonts.questrial(
                fontSize: 16,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                context.push('/asesoria');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF183D6B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'CONTACTAR',
                style: GoogleFonts.barlow(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLarge = false,
    int badgeCount = 0,
  }) {
    final double size = isLarge ? 90 : 75;

    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: const Color(0xFF183D6B), // Darker blue for contrast
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(icon, size: size * 0.45, color: Colors.white),
                ),
              ),
              if (badgeCount > 0)
                Positioned(
                  right: -3,
                  top: -3,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : badgeCount.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 100,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.questrial(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.legacyBlue1,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomPromoBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF183D6B), // Dark teal/blue from mockup
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Descubre contenido exclusivo y masterclass en vivo para maximizar tu legado.',
              style: GoogleFonts.questrial(color: Colors.white, fontSize: 14),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16592E), // Green button
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(
              'Ver más',
              style: GoogleFonts.barlow(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
