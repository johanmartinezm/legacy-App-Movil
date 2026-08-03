import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/event_model.dart';
import '../../../domain/models/workshop_model.dart';
import '../../../domain/providers/events_provider.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../config/theme/app_theme.dart';
import '../../widgets/eventos/rating_dialog.dart';

class CronogramaScreen extends StatelessWidget {
  final EventModel event;

  const CronogramaScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    // Group workshops by date
    final Map<String, List<WorkshopModel>> workshopsByDate = {};
    for (var workshop in event.workshops) {
      final String dateKey = DateFormat(
        'yyyy-MM-dd',
      ).format(workshop.startDateTime);
      if (!workshopsByDate.containsKey(dateKey)) {
        workshopsByDate[dateKey] = [];
      }
      workshopsByDate[dateKey]!.add(workshop);
    }

    final List<String> dates = workshopsByDate.keys.toList()..sort();

    return DefaultTabController(
      length: dates.isEmpty ? 1 : dates.length,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            'Cronograma: ${event.title}',
            style: GoogleFonts.barlow(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppTheme.legacyBlue1,
          foregroundColor: Colors.white,
          bottom: dates.isEmpty
              ? null
              : TabBar(
                  isScrollable: true,
                  labelColor: Colors.white, // Color de la pestaña seleccionada
                  unselectedLabelColor: Colors.white.withValues(
                    alpha: 0.7,
                  ), // Color de las no seleccionadas
                  indicatorColor: Colors.white, // Color de la línea de abajo
                  tabs: dates.map((date) {
                    final DateTime dt = DateTime.parse(date);
                    return Tab(text: DateFormat('EEE, d MMM', 'es').format(dt));
                  }).toList(),
                ),
        ),
        body: dates.isEmpty
            ? const Center(
                child: Text('No hay talleres programados para este evento.'),
              )
            : TabBarView(
                children: dates.map((date) {
                  final workshops = workshopsByDate[date]!;

                  // Group workshops by time within this date
                  final Map<String, List<WorkshopModel>> workshopsByTime = {};
                  for (var w in workshops) {
                    final startTime = DateFormat(
                      'HH:mm',
                    ).format(w.startDateTime);
                    final endTime = DateFormat('HH:mm').format(w.endDateTime);
                    final timeKey = '$startTime - $endTime';
                    if (!workshopsByTime.containsKey(timeKey)) {
                      workshopsByTime[timeKey] = [];
                    }
                    workshopsByTime[timeKey]!.add(w);
                  }

                  final List<String> times = workshopsByTime.keys.toList()
                    ..sort();

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: times.length,
                    itemBuilder: (context, index) {
                      final time = times[index];
                      final concurrentWorkshops = workshopsByTime[time]!;
                      return _TimeSlotGroup(
                        time: time,
                        workshops: concurrentWorkshops,
                      );
                    },
                  );
                }).toList(),
              ),
      ),
    );
  }
}

class _TimeSlotGroup extends StatelessWidget {
  final String time;
  final List<WorkshopModel> workshops;

  const _TimeSlotGroup({required this.time, required this.workshops});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.legacyBlue1,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                time,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // If there are multiple workshops, show them in columns
              if (workshops.length > 1) {
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: workshops.map((workshop) {
                    // Try to fit 3 columns if possible, otherwise 2, otherwise 1
                    double itemWidth;
                    if (constraints.maxWidth > 900) {
                      itemWidth = (constraints.maxWidth - 24) / 3;
                    } else if (constraints.maxWidth > 600) {
                      itemWidth = (constraints.maxWidth - 12) / 2;
                    } else {
                      // Even on mobile, if the user wants "parallel",
                      // maybe 2 columns if narrow?
                      // Let's stick to 1 on very narrow but 2 on medium.
                      itemWidth = constraints.maxWidth;
                    }

                    return SizedBox(
                      width: itemWidth,
                      child: _WorkshopItem(workshop: workshop),
                    );
                  }).toList(),
                );
              }
              // Single workshop takes full width
              return _WorkshopItem(workshop: workshops[0]);
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _WorkshopItem extends StatelessWidget {
  final WorkshopModel workshop;

  const _WorkshopItem({required this.workshop});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: const BoxDecoration(
                color: AppTheme.legacyBlue3,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            workshop.name,
                            style: GoogleFonts.barlow(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Consumer2<EventsProvider, AuthProvider>(
                          builder: (context, provider, auth, child) {
                            final isInAgenda = provider.isInAgenda(workshop.id);
                            final token = auth.token;

                            return IconButton(
                              icon: Icon(
                                isInAgenda
                                    ? Icons.bookmark
                                    : Icons.bookmark_add_outlined,
                                color: isInAgenda
                                    ? AppTheme.legacyBlue1
                                    : Colors.grey,
                                size: 20,
                              ),
                              onPressed: () {
                                if (token == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Debes iniciar sesión para usar la agenda',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                if (isInAgenda) {
                                  provider
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
                                } else {
                                  provider.addToAgenda(workshop, token).then((
                                    success,
                                  ) {
                                    if (success && context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Añadido a tu agenda'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    } else if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Error al actualizar agenda',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  });
                                }
                              },
                              tooltip: isInAgenda
                                  ? 'Quitar de mi agenda'
                                  : 'Añadir a mi agenda',
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          workshop.room,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.person, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          workshop.speaker,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
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
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
