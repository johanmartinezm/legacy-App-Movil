import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme/app_theme.dart';
import '../../domain/models/pagina_informativa_model.dart';

/// Los dos caminos de Legacy Board, al pie de su página informativa.
///
/// Mientras no existan los formularios A (consejero) y B (empresario) del plan
/// de Legacy Board, cada botón abre Contáctenos con el asunto ya escrito: el
/// mensaje llega a «Mensajes de contacto» del panel y al correo, y el equipo
/// sabe de entrada qué quiere la persona. Decisión del 2026-10-13. Cuando
/// existan los formularios, cada botón llevará al suyo.
///
/// Los textos (pregunta y botones) los edita el panel desde el 2026-10-15; el
/// asunto no, porque es como el equipo reconoce los mensajes. Un texto vacío
/// pinta el de siempre.
class BotonesLegacyBoard extends StatelessWidget {
  final String pregunta;
  final String textoSerParte;
  final String textoBuscar;

  const BotonesLegacyBoard({
    super.key,
    this.pregunta = '',
    this.textoSerParte = '',
    this.textoBuscar = '',
  });

  /// Para `PaginaInformativaScreen.acciones`: toma los textos de la página.
  static Widget desdePagina(PaginaInformativa pagina) => BotonesLegacyBoard(
        pregunta: pagina.preguntaAcciones,
        textoSerParte: pagina.botonPrincipal,
        textoBuscar: pagina.botonSecundario,
      );

  static const asuntoSerParte = 'Legacy Board: quiero ser parte';
  static const asuntoBuscar = 'Legacy Board: quiero buscar consejeros';

  static const preguntaPorDefecto = '¿Cómo quiere participar?';
  static const serPartePorDefecto = 'Quiero ser parte';
  static const buscarPorDefecto = 'Quiero buscar';

  static String _o(String texto, String porDefecto) =>
      texto.trim().isEmpty ? porDefecto : texto.trim();

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
          _o(pregunta, preguntaPorDefecto),
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
          label: Text(_o(textoSerParte, serPartePorDefecto), style: estiloTexto),
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
          label: Text(_o(textoBuscar, buscarPorDefecto), style: estiloTexto),
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
