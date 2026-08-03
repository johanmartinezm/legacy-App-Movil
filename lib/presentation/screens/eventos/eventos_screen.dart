import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../../config/theme/app_theme.dart';
import '../../../domain/models/event_model.dart';
import '../../../domain/providers/events_provider.dart';
import '../../../domain/providers/auth_provider.dart';
import 'event_purchase_detail_screen.dart';
import 'agenda_screen.dart';

class EventosScreen extends StatefulWidget {
  const EventosScreen({super.key});

  @override
  State<EventosScreen> createState() => _EventosScreenState();
}

class _EventosScreenState extends State<EventosScreen> {
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es', null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final eventsProvider = Provider.of<EventsProvider>(
        context,
        listen: false,
      );
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      eventsProvider.loadEvents();
      if (authProvider.token != null) {
        eventsProvider.loadAgenda(authProvider.token!);
      }
    });
  }

  void _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (shouldLogout == true) {
      Provider.of<AuthProvider>(context, listen: false).logout();
    }
  }

  String _selectedTab = 'próximos'; // 'próximos', 'pasados', 'mis_registros'

  @override
  Widget build(BuildContext context) {
    final eventsProvider = Provider.of<EventsProvider>(context);
    final events = eventsProvider.events;
    final isLoading = eventsProvider.isLoading;

    // Filter events based on selected tab
    List<EventModel> filteredEvents = [];
    if (_selectedTab == 'próximos') {
      filteredEvents = events;
    } else if (_selectedTab == 'pasados') {
      filteredEvents = []; // No past events for now
    } else if (_selectedTab == 'mis_registros') {
      filteredEvents = events.where((e) => e.actionStatus == 'registered' || e.actionStatus == 'reminder').toList();
    }

    return Scaffold(
      backgroundColor: AppTheme.legacyBlue1,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'fab_agenda',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AgendaScreen()),
              );
            },
            backgroundColor: const Color(0xFF0B1A2E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: const BorderSide(color: Color(0xFFC9A24B), width: 1.5),
            ),
            child: const Icon(Icons.calendar_month, color: Color(0xFFC9A24B)),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'fab_eventos',
            onPressed: () {
              context.push('/cart');
            },
            backgroundColor: const Color(0xFFE3C272),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(Icons.shopping_cart, color: Color(0xFF050B15)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header Section
            _buildHeader(context),

            // Tab Segment Control
            _buildTabSegments(),
            const SizedBox(height: 12),

            // Main Content Area
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredEvents.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: filteredEvents.length,
                          itemBuilder: (context, index) {
                            return _buildCompactEventCard(context, filteredEvents[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Back Button
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
                shape: BoxShape.circle,
                color: const Color(0xFF0B1A2E).withValues(alpha: 0.6),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Eventos',
                  style: GoogleFonts.barlow(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Experiencias y encuentros',
                  style: GoogleFonts.questrial(
                    fontSize: 12,
                    color: const Color(0xFF90A4BA),
                  ),
                ),
              ],
            ),
          ),
          // Menu Button
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'logout') _confirmLogout();
              if (value == 'profile') context.push('/profile');
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Text('Mi perfil'),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Text('Salir'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabSegments() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: _buildTabButton('Próximos', 'próximos')),
          const SizedBox(width: 10),
          Expanded(child: _buildTabButton('Pasados', 'pasados')),
          const SizedBox(width: 10),
          Expanded(child: _buildTabButton('Mis registros', 'mis_registros')),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, String tabValue) {
    final isSelected = _selectedTab == tabValue;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = tabValue;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE3C272) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFE3C272) : Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.barlow(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isSelected ? const Color(0xFF050B15) : const Color(0xFF90A4BA),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String msg = 'No hay eventos disponibles en esta sección.';
    if (_selectedTab == 'pasados') {
      msg = 'No tienes eventos pasados registrados.';
    } else if (_selectedTab == 'mis_registros') {
      msg = 'Aún no te has registrado a ningún evento.';
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Text(
          msg,
          textAlign: TextAlign.center,
          style: GoogleFonts.questrial(
            fontSize: 14,
            color: const Color(0xFF90A4BA),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactEventCard(BuildContext context, EventModel event) {
    final isLSO = event.category.toLowerCase() == 'workshop' || event.title.toLowerCase().contains('lso');
    final isSummit = event.category.toLowerCase() == 'summit';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1A2E).withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFF2A4A75).withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EventPurchaseDetailScreen(event: event),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Title, Subtitle, Note
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: GoogleFonts.barlow(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        event.date,
                        style: GoogleFonts.questrial(
                          fontSize: 12,
                          color: const Color(0xFF90A4BA),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isSummit ? 'Preventa hasta 30 jul' : 'Gratis',
                        style: GoogleFonts.questrial(
                          fontSize: 11,
                          color: const Color(0xFF647689),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Right side: Badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isLSO)
                      // Golden "L" Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3C272),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'L',
                          style: GoogleFonts.barlow(
                            color: const Color(0xFF050B15),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      )
                    else
                      // Standard badge (ABIERTO or GRATIS)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSummit
                              ? const Color(0xFF54C6A8).withValues(alpha: 0.12)
                              : const Color(0xFF5BB0E6).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSummit
                                ? const Color(0xFF54C6A8).withValues(alpha: 0.4)
                                : const Color(0xFF5BB0E6).withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          isSummit ? 'ABIERTO' : 'GRATIS',
                          style: GoogleFonts.barlow(
                            color: isSummit ? const Color(0xFF54C6A8) : const Color(0xFF5BB0E6),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

