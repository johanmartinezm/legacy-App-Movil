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
import '../../widgets/boton_volver.dart';

// Mismos tonos que el detalle del evento, desde donde se llega aquí. Hasta el
// 2026-10-28 la pantalla iba en blanco con el tema por defecto, y el nombre del
// taller salía en blanco sobre blanco.
const _cian = Color(0xFF00F2FE);
const _textoSecundario = Color(0xFF9FB2C2);

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
        backgroundColor: AppTheme.legacyBlue1,
        appBar: AppBar(
          backgroundColor: AppTheme.legacyBlue1,
          elevation: 0,
          leading: const BotonVolver(),
          centerTitle: true,
          title: Text(
            'Cronograma',
            style: GoogleFonts.barlow(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          bottom: dates.isEmpty
              ? null
              : TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: _cian,
                  unselectedLabelColor: _textoSecundario,
                  indicatorColor: _cian,
                  dividerColor: AppTheme.legacyBlue2,
                  labelStyle: GoogleFonts.barlow(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: GoogleFonts.barlow(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: dates.map((date) {
                    final DateTime dt = DateTime.parse(date);
                    return Tab(text: DateFormat('EEE, d MMM', 'es').format(dt));
                  }).toList(),
                ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.8, -0.8),
              radius: 1.5,
              colors: [
                AppTheme.legacyBlue2,
                AppTheme.legacyBlue2,
                AppTheme.legacyBlue1,
              ],
              stops: [0.0, 0.3, 1.0],
            ),
          ),
          child: dates.isEmpty
              ? Center(
                  child: Text(
                    'No hay talleres programados para este evento.',
                    style: GoogleFonts.questrial(color: _textoSecundario),
                  ),
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
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
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
            // Igual que la etiqueta «REGISTRO ABIERTO» del detalle.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _cian.withValues(alpha: 0.5),
                  width: 1,
                ),
                color: _cian.withValues(alpha: 0.05),
              ),
              child: Text(
                time,
                style: GoogleFonts.barlow(
                  color: _cian,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Divider(color: AppTheme.legacyBlue2, thickness: 0.5),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: EdgeInsets.zero,
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
      // Como la ficha técnica del detalle del evento.
      decoration: BoxDecoration(
        color: AppTheme.legacySurface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.legacyBlue2.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: const BoxDecoration(
                color: AppTheme.legacyActive,
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
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
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
                                color: isInAgenda ? _cian : _textoSecundario,
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
                    // Wrap y no Row: con un expositor de nombre largo la
                    // fila se desbordaba.
                    Wrap(
                      spacing: 16,
                      runSpacing: 6,
                      children: [
                        _Dato(
                          icono: Icons.place_outlined,
                          texto: workshop.room,
                        ),
                        _Dato(
                          icono: Icons.person_outline,
                          texto: workshop.speaker,
                        ),
                      ],
                    ),
                    if (workshop.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        workshop.description.trim(),
                        style: GoogleFonts.questrial(
                          color: AppTheme.legacyWhite.withValues(alpha: 0.9),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: !workshop.terminado
                          ? Text(
                              'Podrás calificarlo al terminar',
                              style: GoogleFonts.barlow(
                                color: _textoSecundario,
                                fontSize: 12,
                              ),
                            )
                          : TextButton.icon(
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
                                foregroundColor: _cian,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
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

class _Dato extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _Dato({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    if (texto.trim().isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 15, color: _textoSecundario),
        const SizedBox(width: 5),
        Text(
          texto,
          style: GoogleFonts.barlow(
            color: _textoSecundario,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
