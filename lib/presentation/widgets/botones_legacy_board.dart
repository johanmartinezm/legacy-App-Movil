import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme/app_theme.dart';

/// Los dos caminos de Legacy Board, al pie de su página informativa.
///
/// Mientras no existan los formularios A (consejero) y B (empresario) del plan
/// de Legacy Board, cada botón abre Contáctenos con el asunto ya escrito: el
/// mensaje llega a «Mensajes de contacto» del panel y al correo, y el equipo
/// sabe de entrada qué quiere la persona. Decisión del 2026-10-13. Cuando
/// existan los formularios, cada botón llevará al suyo.
class BotonesLegacyBoard extends StatelessWidget {
  const BotonesLegacyBoard({super.key});

  static const asuntoSerParte = 'Legacy Board: quiero ser parte';
  static const asuntoBuscar = 'Legacy Board: quiero buscar consejeros';

  void _contactar(BuildContext context, String asunto) {
    context.push(Uri(path: '/contacto', queryParameters: {'asunto': asunto}).toString());
  }

  @override
  Widget build(BuildContext context) {
    final forma = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    final estiloTexto = GoogleFonts.barlow(fontSize: 16, fontWeight: FontWeight.bold);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '¿Cómo quiere participar?',
          style: GoogleFonts.barlow(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          key: const Key('legacy-board-ser-parte'),
          onPressed: () => _contactar(context, asuntoSerParte),
          icon: const Icon(Icons.how_to_reg_outlined),
          label: Text('Quiero ser parte', style: estiloTexto),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.legacyActive,
            foregroundColor: AppTheme.legacyBlue1,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: forma,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const Key('legacy-board-buscar'),
          onPressed: () => _contactar(context, asuntoBuscar),
          icon: const Icon(Icons.person_search_outlined),
          label: Text('Quiero buscar', style: estiloTexto),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: AppTheme.legacyActive, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: forma,
          ),
        ),
      ],
    );
  }
}
