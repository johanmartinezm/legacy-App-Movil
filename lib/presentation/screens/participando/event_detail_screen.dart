import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:legacy_app/domain/models/events_data.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../data/config/image_helper.dart';

class EventDetailScreen extends StatelessWidget {
  final EventItem event;

  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    bool isPast = event.status == 'Finalizado';

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Header Image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                   Image.network(
                    ImageHelper.getProxiedImageUrl(event.imageUrl),
                    fit: BoxFit.cover,
                    color: isPast ? Colors.grey : null,
                    colorBlendMode: isPast ? BlendMode.saturation : null,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image,
                          size: 50, color: Colors.grey),
                    ),
                  ),
                  // Gradient for text visibility
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black54,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(
                event.title,
                style: GoogleFonts.barlow(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Content
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isPast
                              ? Colors.grey
                              : AppTheme.legacyBlue1,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          event.status.toUpperCase(),
                          style: GoogleFonts.mulish(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Info Row
                      _buildInfoRow(Icons.calendar_today, event.date),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.access_time, event.time ?? ''),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                          event.type == 'Virtual'
                              ? Icons.computer
                              : Icons.location_on,
                          event.location ?? ''),
                      
                      const SizedBox(height: 24),

                      // Price & Registration
                      if (!isPast)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Precio',
                                    style: GoogleFonts.mulish(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    '\$${event.price}',
                                    style: GoogleFonts.barlow(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.legacyGreenDark,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  // Navigate to Registration Form
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Navegar a Registro')),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.legacyOrange,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32, vertical: 12),
                                ),
                                child: const Text('Inscribirme'),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Description
                      Text(
                        'Descripción',
                        style: GoogleFonts.barlow(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.description,
                        style: GoogleFonts.mulish(
                          fontSize: 16,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Agenda
                      if (event.agenda.isNotEmpty) ...[
                        Text(
                          'Agenda',
                          style: GoogleFonts.barlow(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...event.agenda.map((item) => _buildAgendaItem(item)),
                        const SizedBox(height: 24),
                      ],

                      // Speakers
                      if (event.speakers.isNotEmpty) ...[
                        Text(
                          'Speakers',
                          style: GoogleFonts.barlow(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 140, // Height for avatar + name + role
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: event.speakers.length,
                            itemBuilder: (context, index) {
                              return _buildSpeakerItem(event.speakers[index]);
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String? text) {
    final display = text ?? '-';
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.legacyBlue3),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            display,
            style: GoogleFonts.mulish(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAgendaItem(AgendaItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.legacyBlue4.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              item.time,
              textAlign: TextAlign.center,
              style: GoogleFonts.barlow(
                fontWeight: FontWeight.bold,
                color: AppTheme.legacyBlue2,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.activity,
                  style: GoogleFonts.barlow(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  item.description,
                  style: GoogleFonts.mulish(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeakerItem(Speaker speaker) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundImage: NetworkImage(
                ImageHelper.getProxiedImageUrl(speaker.avatarUrl)),
            backgroundColor: Colors.grey[200],
          ),
          const SizedBox(height: 8),
          Text(
            speaker.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.barlow(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            speaker.role,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.mulish(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
