import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:legacy_app/domain/models/event_model.dart';
import '../../../data/config/image_helper.dart';
import '../../widgets/eventos/event_action_button.dart';
import '../../widgets/eventos/event_survey_button.dart';
import '../../widgets/boton_volver.dart';

class EventPurchaseDetailScreen extends StatelessWidget {
  final EventModel event;

  const EventPurchaseDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    // Determine the badge text based on event details
    final String badgeText = event.isFree ? 'REGISTRO ABIERTO' : 'PREVENTA ABIERTA';

    final esSummit = event.category.toLowerCase() == 'summit';
    final speaker = event.speaker?.trim() ?? '';
    final modelo = event.model?.trim() ?? '';
    final incluye = itemsDeIncluye(event.includes);
    final filasFicha = <Widget>[
      if (speaker.isNotEmpty) _buildInfoRow('Speakers', speaker),
      if (modelo.isNotEmpty) _buildInfoRow('Modelo', modelo),
      // Un solo ítem cabe en la columna de la derecha; varios se leían como un
      // bloque de 30 líneas alineado a la derecha, con « · » pegado a los
      // guiones que ya trae el texto. Van como lista a lo ancho.
      if (incluye.length == 1) _buildInfoRow('Incluye', incluye.first),
      if (incluye.length > 1) _buildListaIncluye(incluye),
      if (esSummit)
        _buildInfoRow(
          'Alumni Summit',
          'Acceso a Legacy+',
          valueColor: const Color(0xFFD9A74A),
        ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF162540),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BotonVolver(),
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
              Color(0xFF183D6B), // Accent steel blue
              Color(0xFF183D6B), // Dark blue-gray
              Color(0xFF162540), // Ultra dark base
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
                            color: Color(0xFF9FB2C2),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${event.location ?? 'JW Marriott Bogotá'} • ${event.date}',
                              style: GoogleFonts.barlow(
                                color: const Color(0xFF9FB2C2),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Description
                      //
                      // El párrafo ya existía y ya traía el dato real
                      // (`event.description`, comprobado contra producción:
                      // el Summit trae una descripción real de dos frases).
                      // Lo que faltaba era un rótulo: sin título, un párrafo
                      // suelto entre la ubicación y la ficha técnica no se lee
                      // como "la descripción del evento" — se confunde con
                      // cualquier otro texto de la pantalla.
                      Text(
                        'DESCRIPCIÓN',
                        style: GoogleFonts.barlow(
                          color: const Color(0xFFD9A74A),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        // El texto de respaldo anterior era del propio Legacy
                        // Summit («39 sesiones, contenido de Harvard...») y
                        // aparecía igual en cualquier otro evento sin
                        // descripción, como si fuera suya. Ahora que el
                        // párrafo lleva el rótulo «DESCRIPCIÓN», mostrar
                        // contenido de otro evento sería más engañoso, no
                        // menos.
                        event.description.isNotEmpty
                            ? event.description
                            : 'Este evento todavía no tiene descripción.',
                        style: GoogleFonts.questrial(
                          fontSize: 15,
                          color: const Color(0xFFE8EEF5).withValues(alpha: 0.9),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Ficha técnica
                      //
                      // Hasta el 2026-10-12 «Modelo», «Alumni Summit» y la nota
                      // verde eran texto fijo, y Speakers e Incluye caían a los
                      // datos del Summit cuando el evento no traía los suyos: una
                      // masterclass anunciaba el campus de 45 días, el libro y la
                      // suscripción a El Espectador como si fueran suyos. Ahora
                      // cada fila sale solo si el evento tiene el dato, y lo
                      // propio del Summit solo en los eventos de esa categoría.
                      if (filasFicha.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B3156).withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF183D6B).withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              for (var i = 0; i < filasFicha.length; i++) ...[
                                if (i > 0)
                                  const Divider(color: Color(0xFF183D6B), thickness: 0.5, height: 24),
                                filasFicha[i],
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      if (esSummit)
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
                // En un evento terminado no cabe "reservar cupo": lo que procede
                // es pedir la opinión. En el resto, el botón lo decide
                // EventActionButton según la inscripción REAL del usuario.
                child: event.isPast
                    ? EventSurveyButton(
                        eventId: event.id,
                        eventTitle: event.title,
                      )
                    : EventActionButton(event: event),
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
          color: const Color(0xFF1B3156),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF183D6B).withValues(alpha: 0.5),
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
          color: const Color(0xFF183D6B).withValues(alpha: 0.5),
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
                color: const Color(0xFF1B3156),
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
                      const Color(0xFF162540).withValues(alpha: 0.7),
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

  Widget _buildListaIncluye(List<String> items) {
    return Column(
      key: const Key('ficha-incluye-lista'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Incluye',
          style: GoogleFonts.barlow(
            color: const Color(0xFF9FB2C2),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6, right: 10),
                  child: Icon(Icons.circle, size: 6, color: Color(0xFFD9A74A)),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: GoogleFonts.questrial(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
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
              color: const Color(0xFF9FB2C2),
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

/// Los ítems de «Incluye», uno por línea como lo pide el panel. Se quita la
/// viñeta que traiga escrita cada línea («- », «• », «* ») para no repetirla
/// junto a la de la lista, y se descartan las líneas vacías.
List<String> itemsDeIncluye(String? includes) {
  if (includes == null) return const [];
  return includes
      .split(RegExp(r'\r?\n'))
      .map((l) => l.trim().replaceFirst(RegExp(r'^[-•*]\s*'), '').trim())
      .where((l) => l.isNotEmpty)
      .toList();
}
