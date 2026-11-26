import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/theme/app_theme.dart';
import '../../domain/models/pagina_informativa_model.dart';
import '../../domain/providers/auth_provider.dart';

/// Los dos caminos de Legacy Board, al pie de su página informativa.
///
/// **Solo los ve quien tiene el plus** (decisiones 4 y 6 del plan
/// reports/20261002_plan_legacy_board_formularios.md): sin él, la página es
/// solo informativa. El backend lo vuelve a comprobar al abrir y al enviar
/// cada formulario, así que esconderlos es para no ofrecer lo que no se puede
/// usar, no la protección.
///
/// - «Quiero ser parte» abre el Formulario A, la postulación del consejero
///   (desde el 2026-11-25).
/// - «Quiero buscar» sigue abriendo Contáctenos con el asunto escrito, como
///   desde el 2026-10-13, hasta que exista el Formulario B (fase 4 del plan).
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

  /// Ruta del Formulario A (postulación del consejero).
  static const rutaSerParte = '/legacy-board/formulario/A';
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
    if (!context.watch<AuthProvider>().esPlus) return const SizedBox.shrink();
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
          onPressed: () => context.push(rutaSerParte),
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
