import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../config/theme/app_theme.dart';
import '../../../domain/models/workshop_model.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/events_provider.dart';
import '../../widgets/boton_volver.dart';
import '../../widgets/eventos/rating_dialog.dart';

const _cian = Color(0xFF00F2FE);
const _textoSecundario = Color(0xFF9FB2C2);

/// «Mi agenda»: los workshops que elegí al inscribirme, agrupados por evento.
///
/// Hasta el 2026-11-06 era una pantalla clara con AppBar de Material, que no se
/// parecía al resto de la app: el nombre del evento y «Calificar experiencia»
/// salían en azul oscuro sobre la tarjeta azul y casi no se leían. Ahora sigue
/// el estilo de «Mi credencial» (cabecera y fondo) y del cronograma (tarjetas).
class AgendaScreen extends StatelessWidget {
  const AgendaScreen({super.key});

  Future<void> _recargar(BuildContext context) async {
    final token = context.read<AuthProvider>().token;
    if (token != null) await context.read<EventsProvider>().loadAgenda(token);
  }

  /// Un grupo por evento: primero los que vienen (del más próximo al más
  /// lejano) y después los pasados (del más reciente al más antiguo).
  static List<List<WorkshopModel>> agrupar(
    List<WorkshopModel> agenda, {
    DateTime? ahora,
  }) {
    final ref = ahora ?? DateTime.now();
    final porEvento = <String, List<WorkshopModel>>{};
    for (final w in agenda) {
      porEvento.putIfAbsent(w.eventId, () => []).add(w);
    }
    final grupos = porEvento.values.toList();
    for (final g in grupos) {
      g.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    }
    bool pasado(List<WorkshopModel> g) =>
        g.every((w) => w.endDateTime.isBefore(ref));
    final proximos = grupos.where((g) => !pasado(g)).toList()
      ..sort((a, b) => a.first.startDateTime.compareTo(b.first.startDateTime));
    final pasados = grupos.where(pasado).toList()
      ..sort((a, b) => b.first.startDateTime.compareTo(a.first.startDateTime));
    return [...proximos, ...pasados];
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventsProvider>();
    final grupos = agrupar(provider.agenda);

    return Scaffold(
      backgroundColor: AppTheme.legacyBlue1,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BotonVolver(),
        title: Text(
          'Mi agenda',
          style: GoogleFonts.barlow(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => _recargar(context),
        color: AppTheme.legacyActive,
        child: provider.isLoading && grupos.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : grupos.isEmpty
            ? _buildVacia()
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                // Abajo, sitio para que el botón de la credencial no tape la
                // última tarjeta.
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Los workshops que elegiste al inscribirte. Puedes '
                      'cambiarlos desde el evento hasta el día anterior.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.questrial(
                        fontSize: 13,
                        color: _textoSecundario,
                        height: 1.4,
                      ),
                    ),
                  ),
                  for (final grupo in grupos) ..._buildGrupo(context, grupo),
                ],
              ),
      ),
      // Lleva a «Mi credencial», que muestra el acceso de todos los eventos
      // inscritos. Mismo estilo que el botón de la agenda en Eventos.
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_credencial',
        onPressed: () => context.push('/mi-credencial'),
        backgroundColor: AppTheme.legacySurface,
        foregroundColor: AppTheme.legacyActive,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: AppTheme.legacyActive, width: 1.5),
        ),
        icon: const Icon(Icons.qr_code),
        label: Text(
          'Mi credencial',
          style: GoogleFonts.barlow(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  List<Widget> _buildGrupo(BuildContext context, List<WorkshopModel> grupo) {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
        child: Text(
          grupo.first.eventTitle,
          style: GoogleFonts.barlow(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _textoSecundario,
          ),
        ),
      ),
      for (final w in grupo) _TarjetaAgenda(workshop: w),
      const SizedBox(height: 8),
    ];
  }

  Widget _buildVacia() {
    // Desplazable para que deslizar hacia abajo también recargue aquí.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.event_note_outlined,
                    size: 56,
                    color: _textoSecundario,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes workshops en tu agenda.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.barlow(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Al inscribirte a un evento eliges sus workshops.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.questrial(
                      fontSize: 14,
                      color: _textoSecundario,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de un workshop elegido, con el mismo aspecto que las del cronograma.
class _TarjetaAgenda extends StatelessWidget {
  final WorkshopModel workshop;

  const _TarjetaAgenda({required this.workshop});

  @override
  Widget build(BuildContext context) {
    final dia = DateFormat("EEE d 'de' MMM", 'es').format(workshop.startDateTime);
    final horario =
        '${DateFormat('HH:mm').format(workshop.startDateTime)} – '
        '${DateFormat('HH:mm').format(workshop.endDateTime)}';

    return Container(
      key: Key('agenda-${workshop.id}'),
      margin: const EdgeInsets.only(bottom: 12),
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
                    Text(
                      workshop.name,
                      style: GoogleFonts.barlow(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Wrap y no Row: con una sala o un expositor largos la
                    // fila se desbordaría.
                    Wrap(
                      spacing: 16,
                      runSpacing: 6,
                      children: [
                        _Dato(icono: Icons.calendar_today_outlined, texto: dia),
                        _Dato(icono: Icons.schedule, texto: horario),
                        if (workshop.room.trim().isNotEmpty)
                          _Dato(icono: Icons.place_outlined, texto: workshop.room),
                        if (workshop.speaker.trim().isNotEmpty)
                          _Dato(
                            icono: Icons.person_outline,
                            texto: workshop.speaker,
                          ),
                      ],
                    ),
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
                              onPressed: () => showDialog(
                                context: context,
                                builder: (context) => RatingDialog(
                                  itemName: workshop.name,
                                  itemId: workshop.id,
                                ),
                              ),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 15, color: _textoSecundario),
        const SizedBox(width: 5),
        Text(
          texto,
          style: GoogleFonts.questrial(color: _textoSecundario, fontSize: 13),
        ),
      ],
    );
  }
}
