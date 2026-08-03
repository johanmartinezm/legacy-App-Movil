import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../domain/providers/events_provider.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../config/theme/app_theme.dart';
import '../../widgets/eventos/qr_attendance_dialog.dart';
import '../../widgets/eventos/rating_dialog.dart';

class AgendaScreen extends StatelessWidget {
  const AgendaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eventsProvider = Provider.of<EventsProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final agenda = eventsProvider.agenda;
    final token = authProvider.token;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Mi Agenda Personal',
          style: GoogleFonts.barlow(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.legacyBlue1,
        foregroundColor: Colors.white,
      ),
      body: agenda.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No tienes talleres en tu agenda.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Inscríbete en los cronogramas de los eventos.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: agenda.length,
              itemBuilder: (context, index) {
                final workshop = agenda[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    workshop.eventTitle,
                                    style: GoogleFonts.barlow(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.legacyBlue1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    workshop.name,
                                    style: GoogleFonts.barlow(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.bookmark_remove_outlined,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                if (token != null) {
                                  eventsProvider
                                      .removeFromAgenda(workshop.id, token)
                                      .then((success) {
                                        if (success && context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Eliminado de tu agenda',
                                              ),
                                              duration: Duration(seconds: 1),
                                            ),
                                          );
                                        }
                                      });
                                }
                              },
                              tooltip: 'Quitar de mi agenda',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${DateFormat('HH:mm').format(workshop.startDateTime)} - ${DateFormat('HH:mm').format(workshop.endDateTime)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat(
                                'd MMM',
                                'es',
                              ).format(workshop.startDateTime),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              workshop.room,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.green,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'En mi lista',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            TextButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => RatingDialog(
                                    itemName: workshop.name,
                                    itemId: workshop.id,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.star_outline, size: 16),
                              label: const Text(
                                'Calificar experiencia',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.legacyBlue1,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: agenda.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                // Show QR for the first event in agenda as a representative entry
                showDialog(
                  context: context,
                  builder: (context) => QrAttendanceDialog(
                    eventId: agenda.first.eventId,
                    eventTitle: agenda.first.eventTitle,
                  ),
                );
              },
              backgroundColor: AppTheme.legacyBlue1,
              foregroundColor: Colors.white,
              label: const Text('Presentar QR'),
              icon: const Icon(Icons.qr_code),
            )
          : null,
    );
  }
}
