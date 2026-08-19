import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../config/theme/app_theme.dart';
import '../../../data/services/board_service.dart';
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
                                      onTap: () => _showBoardDialog(context),
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

  Future<List<dynamic>> _loadBoardContacts() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/board_contacts.json',
      );
      final data = await json.decode(response);
      return data['contacts'];
    } catch (e) {
      return [];
    }
  }

    void _showBoardDialog(BuildContext context) async {
    final contacts = await _loadBoardContacts();
    final TextEditingController messageController = TextEditingController();
    bool showForm = false;
    dynamic selectedPerson; // Track selected contact

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            titlePadding: const EdgeInsets.only(top: 25, left: 20, right: 20),
            title: Text(
              showForm
                  ? (selectedPerson != null
                      ? 'CONVERSAR CON ${selectedPerson['name'].toUpperCase()}'
                      : 'ENVÍANOS TU SOLICITUD')
                  : 'LEGACY BOARD',
              textAlign: TextAlign.center,
              style: GoogleFonts.barlow(
                fontWeight: FontWeight.bold,
                color: AppTheme.legacyBlue1,
                letterSpacing: 1.1,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!showForm) ...[
                    Text(
                      'Para ser parte de nuestro board o recibir más información, por favor comunícate con:',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.questrial(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 25),
                    if (contacts.isEmpty)
                      const CircularProgressIndicator()
                    else
                      ...contacts.map(
                        (c) => InkWell(
                          onTap: () {
                            setState(() {
                              selectedPerson = c;
                              showForm = true;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 15,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.legacyBlue1.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.legacyBlue1.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppTheme.legacyBlue1,
                                  child: Icon(
                                    Icons.person,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c['name'],
                                        style: GoogleFonts.barlow(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: AppTheme.legacyBlue1,
                                        ),
                                      ),
                                      Text(
                                        c['position'],
                                        style: GoogleFonts.questrial(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 12,
                                  color: AppTheme.legacyBlue1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedPerson = null;
                            showForm = true;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.legacyOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          '¿QUIERES SER DE NUESTRO BOARD?',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.barlow(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Text(
                      selectedPerson != null
                          ? 'Escribe tu mensaje para ${selectedPerson['name']}:'
                          : 'Escribe un breve mensaje explicando por qué te gustaría integrar nuestro Board estratégico:',
                      style: GoogleFonts.questrial(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: messageController,
                      maxLines: 4,
                      autofocus: true,
                      style: GoogleFonts.questrial(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Añade tu propuesta o mensaje aquí...',
                        hintStyle: GoogleFonts.questrial(
                          color: Colors.grey[400],
                        ),
                        fillColor: Colors.grey[50],
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.legacyBlue1,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final message = messageController.text.trim();
                          if (message.isNotEmpty) {
                            final authProvider =
                                Provider.of<AuthProvider>(context, listen: false);
                            final boardService = BoardService();

                            setState(() => showForm = false); // Hide form
                            // Optimistically show a loading indicator or just handle it
                            // For simplicity, we'll try to send and show result

                            try {
                              await boardService.sendContactMessage(
                                token: authProvider.token ?? '',
                                contactId: selectedPerson?['id'] ?? 'default',
                                message: message,
                              );

                              if (!context.mounted) return;
                              Navigator.pop(context); // Close dialog

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Solicitud enviada con éxito.'),
                                  backgroundColor: AppTheme.legacyGreen,
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.legacyBlue1,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'ENVIAR SOLICITUD',
                          style: GoogleFonts.barlow(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => setState(() => showForm = false),
                      child: Text(
                        'VOLVER',
                        style: GoogleFonts.barlow(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              if (!showForm)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'CERRAR',
                    style: GoogleFonts.barlow(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          );
        },
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
                color: const Color(0xFF1E2F4D).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_person_outlined,
                size: 80,
                color: Color(0xFF1E2F4D),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Espacio Exclusivo',
              textAlign: TextAlign.center,
              style: GoogleFonts.barlow(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E2F4D),
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
                context.go('/asesoria');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E2F4D),
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
                  color: const Color(0xFF1E2F4D), // Darker blue for contrast
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
        color: const Color(0xFF0F3A5D), // Dark teal/blue from mockup
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
