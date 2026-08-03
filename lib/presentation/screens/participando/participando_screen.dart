import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:legacy_app/domain/models/events_data.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../data/config/image_helper.dart';
import 'event_detail_screen.dart';

class ParticipandoScreen extends StatefulWidget {
  const ParticipandoScreen({super.key});

  @override
  State<ParticipandoScreen> createState() => _ParticipandoScreenState();
}

class _ParticipandoScreenState extends State<ParticipandoScreen> {
  EventsData? _data;
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'Todos'; // 'Todos', 'Presencial', 'Virtual'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/events_data.json',
      );
      final data = await json.decode(response);
      setState(() {
        _data = EventsData.fromJson(data);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading events data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theme Colors
    final Color headerColor = AppTheme.legacyBlue1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              color: headerColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '2. PARTICIPANDO',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.barlow(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _data == null
                  ? const Center(child: Text('Error loading data'))
                  : Builder(
                      builder: (context) {
                        // Filter Logic
                        final filteredEvents = _data!.events.where((item) {
                          final matchesSearch = item.title
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase());
                          final matchesFilter =
                              _selectedFilter == 'Todos' ||
                              item.type == _selectedFilter;
                          return matchesSearch && matchesFilter;
                        }).toList();

                        final upcomingEvents = filteredEvents
                            .where((e) => e.status == 'Próximamente')
                            .toList();
                        final pastEvents = filteredEvents
                            .where((e) => e.status == 'Finalizado')
                            .toList();

                        return ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            // Search Bar
                            TextField(
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Buscar eventos...',
                                prefixIcon: const Icon(Icons.search),
                                filled: true,
                                fillColor: const Color(0xFFF5F5F5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Filter Chips
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildFilterChip('Todos'),
                                  const SizedBox(width: 8),
                                  _buildFilterChip('Presencial'),
                                  const SizedBox(width: 8),
                                  _buildFilterChip('Virtual'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Upcoming Events Section
                            if (upcomingEvents.isNotEmpty) ...[
                              Text(
                                '📅 Próximos Eventos',
                                style: GoogleFonts.barlow(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.legacyBlue1,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ...upcomingEvents.map(
                                (item) => _buildEventCard(item),
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Past Events Section
                            if (pastEvents.isNotEmpty) ...[
                              Text(
                                'history Eventos Pasados',
                                style: GoogleFonts.barlow(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 10),
                              ...pastEvents.map(
                                (item) => _buildEventCard(item, isPast: true),
                              ),
                            ],

                            if (upcomingEvents.isEmpty && pastEvents.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: Text(
                                    'No se encontraron eventos',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected =
        _selectedFilter ==
        (label == 'Presencial'
            ? 'Presencial'
            : label == 'Virtual'
            ? 'Virtual'
            : 'Todos');
    // Adjust logic slightly because label "Presencial" maps to filter "Presencial"
    // Ideally use keys, but label works for simple implementation.

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.legacyBlue3 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.legacyBlue3 : Colors.grey,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.mulish(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(EventItem item, {bool isPast = false}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(event: item),
          ),
        );
      },
      child: Card(
        elevation: isPast ? 1 : 2,
        color: isPast ? Colors.grey[100] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                  child: Image.network(
                    ImageHelper.getProxiedImageUrl(item.imageUrl),
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    color: isPast ? Colors.grey : null,
                    colorBlendMode: isPast ? BlendMode.saturation : null,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 140,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.type,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.barlow(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isPast ? Colors.grey[600] : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: isPast ? Colors.grey : AppTheme.legacyBlue3,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.date,
                        style: GoogleFonts.mulish(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.location_on, // Or video_camera_front
                        size: 14,
                        color: isPast ? Colors.grey : AppTheme.legacyBlue3,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.location ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.mulish(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (!isPast)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${item.price}',
                          style: GoogleFonts.barlow(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.legacyGreenDark,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EventDetailScreen(event: item),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.legacyOrange,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 0,
                            ),
                            fixedSize: const Size.fromHeight(32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            'Ver más',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
