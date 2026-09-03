import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../../config/theme/app_theme.dart';
import '../../../domain/models/event_model.dart';
import '../../../domain/utils/event_filters.dart';
import '../../../domain/providers/events_provider.dart';
import '../../../domain/providers/auth_provider.dart';
import 'event_purchase_detail_screen.dart';
import 'agenda_screen.dart';
import '../../widgets/boton_volver.dart';

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

  String _selectedTab = EventTab.proximos;

  // Búsqueda y filtro por categoría: se resuelven sobre la lista ya cargada,
  // sin llamadas nuevas al backend. `GET /api/events` no acepta parámetros y
  // tampoco tiene paginación, así que la lista completa ya está en memoria.
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = kTodasLasCategorias;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _searchQuery.trim().isNotEmpty || _selectedCategory != kTodasLasCategorias;

  @override
  Widget build(BuildContext context) {
    final eventsProvider = Provider.of<EventsProvider>(context);
    final events = eventsProvider.events;
    final isLoading = eventsProvider.isLoading;

    final List<EventModel> tabEvents = eventsForTab(events, _selectedTab);
    final List<String> categories = categoriesOf(tabEvents);
    final List<EventModel> filteredEvents = applyEventFilters(
      tabEvents,
      query: _searchQuery,
      category: _selectedCategory,
    );

    return Scaffold(
      backgroundColor: AppTheme.legacyBlue1,
      // Solo la agenda. El botón del carrito se retiró el 2026-08-20 junto con
      // el carrito entero: un evento de pago se compra desde su propia ficha y
      // lo de LSO se compra en LSO, así que ese icono abría una pantalla que ya
      // no podía tener nada dentro.
      floatingActionButton: FloatingActionButton(
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
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header Section
            _buildHeader(context),

            // Search field
            _buildSearchField(),

            // Tab Segment Control
            _buildTabSegments(),

            // Category filter
            _buildCategoryFilter(categories),
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
          const BotonVolver(),
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

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        textInputAction: TextInputAction.search,
        style: GoogleFonts.questrial(fontSize: 14, color: Colors.white),
        cursorColor: const Color(0xFFE3C272),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: const Color(0xFF0B1A2E).withValues(alpha: 0.65),
          hintText: 'Buscar por nombre, lugar o conferencista',
          hintStyle: GoogleFonts.questrial(
            fontSize: 13,
            color: const Color(0xFF647689),
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF90A4BA),
            size: 20,
          ),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Limpiar búsqueda',
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFF90A4BA),
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: const Color(0xFF2A4A75).withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFE3C272), width: 1.2),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(List<String> categories) {
    // Con una sola categoría el filtro no distingue nada.
    if (categories.length < 2) return const SizedBox.shrink();

    final options = [kTodasLasCategorias, ...categories];
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = _selectedCategory.toLowerCase() == option.toLowerCase();
          final label = option == kTodasLasCategorias ? 'Todas' : _capitalize(option);
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFE3C272).withValues(alpha: 0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFE3C272)
                      : Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              child: Text(
                label,
                style: GoogleFonts.barlow(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? const Color(0xFFE3C272)
                      : const Color(0xFF90A4BA),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  Widget _buildTabSegments() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: _buildTabButton('Próximos', EventTab.proximos)),
          const SizedBox(width: 10),
          Expanded(child: _buildTabButton('Pasados', EventTab.pasados)),
          const SizedBox(width: 10),
          Expanded(child: _buildTabButton('Mis registros', EventTab.misRegistros)),
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
          // Las categorías disponibles cambian con la pestaña: mantener la
          // anterior dejaría el listado vacío sin motivo aparente.
          _selectedCategory = kTodasLasCategorias;
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
    if (_hasActiveFilters) {
      // Sin esto, un filtro que no encaja se confunde con una sección vacía.
      msg = 'Ningún evento coincide con la búsqueda.';
    } else if (_selectedTab == EventTab.pasados) {
      msg = 'Todavía no hay eventos finalizados.';
    } else if (_selectedTab == EventTab.misRegistros) {
      msg = 'Aún no te has registrado a ningún evento.';
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              msg,
              textAlign: TextAlign.center,
              style: GoogleFonts.questrial(
                fontSize: 14,
                color: const Color(0xFF90A4BA),
              ),
            ),
            if (_hasActiveFilters) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: _clearFilters,
                child: Text(
                  'Quitar filtros',
                  style: GoogleFonts.barlow(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE3C272),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedCategory = kTodasLasCategorias;
    });
  }

  Widget _buildCompactEventCard(BuildContext context, EventModel event) {
    final isLSO = event.category.toLowerCase() == 'workshop' || event.title.toLowerCase().contains('lso');
    // Lo que cuesta sale del evento, no de como se llame su categoria. Hasta el
    // 2026-08-19 esto era `event.category == 'summit'`: cualquier evento que no
    // fuera un summit se anunciaba como «Gratis» aunque costara 150.000, porque
    // la unica categoria de pago que existia entonces era esa.
    final esDePago = !event.isFree;
    
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
                      // En un evento finalizado el precio ya no aplica.
                      if (!event.isPast) ...[
                        const SizedBox(height: 4),
                        Text(
                          // priceLabel lo compone EventModel con
                          // CurrencyFormatter: «$ 150.000» o «GRATIS». Aqui el
                          // gratis va en minuscula porque es una nota, no una
                          // insignia. Antes habia una fecha de preventa escrita
                          // a mano —«Preventa hasta 30 jul»— que seguia saliendo
                          // en agosto.
                          event.isFree ? 'Gratis' : event.priceLabel,
                          style: GoogleFonts.questrial(
                            fontSize: 11,
                            color: const Color(0xFF647689),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Right side: Badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (event.isPast)
                      // Finished event: neutral badge, never "ABIERTO"
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF90A4BA).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF90A4BA).withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'FINALIZADO',
                          style: GoogleFonts.barlow(
                            color: const Color(0xFF90A4BA),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 0.8,
                          ),
                        ),
                      )
                    else if (isLSO)
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
                      // Insignia de precio: PREVENTA si cuesta, GRATIS si no.
                      // «PREVENTA» es la misma palabra que usa el detalle del
                      // evento («PREVENTA ABIERTA»), para que quien abra la
                      // ficha lea lo mismo que vio en la lista.
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: esDePago
                              ? const Color(0xFF54C6A8).withValues(alpha: 0.12)
                              : const Color(0xFF5BB0E6).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: esDePago
                                ? const Color(0xFF54C6A8).withValues(alpha: 0.4)
                                : const Color(0xFF5BB0E6).withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          esDePago ? 'PREVENTA' : 'GRATIS',
                          style: GoogleFonts.barlow(
                            color: esDePago ? const Color(0xFF54C6A8) : const Color(0xFF5BB0E6),
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

