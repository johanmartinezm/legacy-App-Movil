import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/workshop_model.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/events_provider.dart';
import 'rating_dialog.dart';

const _cian = Color(0xFF00F2FE);
const _textoSecundario = Color(0xFF9FB2C2);
const _dorado = Color(0xFFFFC107);

/// «Calificar experiencia» de un workshop terminado, o «Tu calificación» con
/// las estrellas si ya lo calificó. Lo usan el cronograma y «Mi agenda»; cada
/// pantalla decide antes si el workshop se puede calificar (terminado, elegido).
///
/// Hasta el 2026-11-09 el botón salía siempre: en un workshop ya calificado se
/// llenaba el formulario y solo al enviarlo se leía «ya calificaste».
class CalificarWorkshop extends StatefulWidget {
  final WorkshopModel workshop;

  const CalificarWorkshop({super.key, required this.workshop});

  @override
  State<CalificarWorkshop> createState() => _CalificarWorkshopState();
}

class _CalificarWorkshopState extends State<CalificarWorkshop> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final token = context.read<AuthProvider>().token;
      if (token == null) return;
      // El provider pide una sola vez por evento, aunque haya varias tarjetas.
      context.read<EventsProvider>().cargarMisCalificaciones(
        widget.workshop.eventId,
        token,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final estrellas = context.select<EventsProvider, int?>(
      (p) => p.calificacionDe(widget.workshop.id),
    );

    if (estrellas != null) {
      return Row(
        key: const Key('workshop-ya-calificado'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tu calificación',
            style: GoogleFonts.barlow(color: _textoSecundario, fontSize: 12),
          ),
          const SizedBox(width: 6),
          Semantics(
            label: '$estrellas de 5 estrellas',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 1; i <= 5; i++)
                  Icon(
                    i <= estrellas ? Icons.star : Icons.star_border,
                    size: 14,
                    color: i <= estrellas ? _dorado : _textoSecundario,
                  ),
              ],
            ),
          ),
        ],
      );
    }

    return TextButton.icon(
      key: const Key('workshop-calificar'),
      onPressed: () => showDialog(
        context: context,
        builder: (context) => RatingDialog(
          itemName: widget.workshop.name,
          itemId: widget.workshop.id,
        ),
      ),
      icon: const Icon(Icons.star_outline, size: 16),
      label: const Text(
        'Calificar experiencia',
        style: TextStyle(fontSize: 12),
      ),
      style: TextButton.styleFrom(
        foregroundColor: _cian,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
