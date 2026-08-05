import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:legacy_app/domain/models/event_model.dart';
import 'package:legacy_app/domain/providers/auth_provider.dart';
import 'package:legacy_app/domain/providers/events_provider.dart';
import 'package:provider/provider.dart';
import '../../../data/config/image_helper.dart';
import '../../widgets/eventos/event_survey_button.dart';
import 'event_payment_screen.dart';

class EventPurchaseDetailScreen extends StatelessWidget {
  final EventModel event;

  const EventPurchaseDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    // Determine the badge text based on event details
    final String badgeText = event.isFree ? 'REGISTRO ABIERTO' : 'PREVENTA ABIERTA';

    return Scaffold(
      backgroundColor: const Color(0xFF050B15),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detalle Evento',
          style: GoogleFonts.barlow(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.8, -0.8),
            radius: 1.5,
            colors: [
              Color(0xFF13304A), // Accent steel blue
              Color(0xFF0E2C3B), // Dark blue-gray
              Color(0xFF050B15), // Ultra dark base
            ],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Image or Calendar Icon placeholder
                      _buildHeaderImage(),
                      const SizedBox(height: 24),

                      // Badge status
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFF00F2FE).withValues(alpha: 0.5),
                              width: 1,
                            ),
                            color: const Color(0xFF00F2FE).withValues(alpha: 0.05),
                          ),
                          child: Text(
                            badgeText,
                            style: GoogleFonts.barlow(
                              color: const Color(0xFF00F2FE),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Event Title
                      Text(
                        event.title,
                        style: GoogleFonts.barlow(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Date and Location row
                      Row(
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            color: Color(0xFF90A4BA),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${event.location ?? 'JW Marriott Bogotá'} • ${event.date}',
                              style: GoogleFonts.barlow(
                                color: const Color(0xFF90A4BA),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Description
                      Text(
                        event.description.isNotEmpty
                            ? event.description
                            : 'Sembrando un legado: honrar lo recibido y prepararnos para la sucesión. La cumbre latinoamericana de familias empresarias: 39 sesiones, contenido de Harvard, ESADE e IESE.',
                        style: GoogleFonts.questrial(
                          fontSize: 15,
                          color: const Color(0xFFE8EEF5).withValues(alpha: 0.9),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Info Card Grid Table
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B1A2E).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF1E3A5F).withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              'Speakers',
                              event.speaker ?? 'Sanjay Goel · M.J. Parada · G. Gómez',
                            ),
                            const Divider(color: Color(0xFF1E3A5F), thickness: 0.5, height: 24),
                            _buildInfoRow('Modelo', '7 dimensiones DINASTÍA'),
                            const Divider(color: Color(0xFF1E3A5F), thickness: 0.5, height: 24),
                            _buildInfoRow(
                              'Incluye',
                              (event.includes != null && event.includes!.trim().isNotEmpty)
                                  ? event.includes!.replaceAll('\n', ' · ')
                                  : 'Campus 45 días · libro · El Espectador 6m',
                            ),
                            const Divider(color: Color(0xFF1E3A5F), thickness: 0.5, height: 24),
                            _buildInfoRow(
                              'Alumni Summit',
                              'Acceso a Legacy+',
                              valueColor: const Color(0xFFD9A74A),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Alert Container (Teal/Green Alumni Note)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0C2423),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF124E48),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Asistir al Summit lo convierte en alumni: acceso a comunidad y descuentos en el ecosistema.',
                          style: GoogleFonts.questrial(
                            color: const Color(0xFF5FF2DE),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),

              // Bottom Action Button Area
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Consumer2<EventsProvider, AuthProvider>(
                  builder: (context, eventsProvider, authProvider, child) {
                    final isRegistered = event.actionStatus == 'registered';
                    final isLoading = eventsProvider.isLoading;

                    // En un evento terminado no cabe "reservar cupo": lo que
                    // procede es pedir la opinión. El backend rechaza con 403 a
                    // quien no se registró, y el diálogo lo dice tal cual.
                    if (event.isPast) {
                      return EventSurveyButton(
                        eventId: event.id,
                        eventTitle: event.title,
                      );
                    }

                    if (isRegistered) {
                      return Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B1A2E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF1E3A5F).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'YA ESTÁS REGISTRADO',
                            style: GoogleFonts.barlow(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF90A4BA),
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      );
                    }

                    // Button content based on cost/type
                    final String buttonText = event.isFree
                        ? 'Reservar cupo gratis'
                        : 'Reservar cupo · preventa';

                    return SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                if (event.isFree) {
                                  final success = await eventsProvider.registerUserToEvent(
                                    event.id,
                                    authProvider.token ?? '',
                                  );
                                  if (success && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('¡Registro exitoso!'),
                                      ),
                                    );
                                    Navigator.pop(context);
                                  } else if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error: ${eventsProvider.errorMessage}',
                                        ),
                                      ),
                                    );
                                  }
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EventPaymentScreen(event: event),
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD9A74A), // Premium gold
                          foregroundColor: const Color(0xFF050B15), // Dark contrast text
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Color(0xFF050B15))
                            : Text(
                                buttonText,
                                style: GoogleFonts.barlow(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderImage() {
    if (event.imageUrl.isEmpty || event.imageUrl.contains('placeholder')) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF0B1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF1E3A5F).withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: Color(0xFFD9A74A),
          ),
        ),
      );
    }

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1E3A5F).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            Image.network(
              ImageHelper.getProxiedImageUrl(event.imageUrl),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF0B1A2E),
                child: const Center(
                  child: Icon(
                    Icons.calendar_today_outlined,
                    size: 64,
                    color: Color(0xFFD9A74A),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF050B15).withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: GoogleFonts.barlow(
              color: const Color(0xFF90A4BA),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.questrial(
              color: valueColor ?? Colors.white,
              fontSize: 14,
              fontWeight: valueColor != null ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
