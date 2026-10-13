import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/theme/app_theme.dart';
import '../../widgets/boton_volver.dart';

/// Un diagnóstico externo: se hace en la web, fuera de la app.
class Diagnostico {
  final String titulo;
  final String url;
  final IconData icono;

  const Diagnostico(this.titulo, this.url, this.icono);
}

/// Pantalla «Diagnósticos», a la que lleva la tarjeta del mismo nombre del
/// Inicio desde el 2026-10-13 (sustituyó allí a Legacy Board). Dos botones que
/// abren cada diagnóstico en el navegador.
class DiagnosticosScreen extends StatelessWidget {
  const DiagnosticosScreen({super.key});

  static const diagnosticos = [
    Diagnostico(
      'Diagnóstico para familias empresarias',
      'https://legacynetworkco.com/legacy-test/?v=ab6c04006660',
      Icons.family_restroom,
    ),
    Diagnostico(
      'Diagnóstico para empresas y organizaciones',
      'https://certificaciongc.legacynetworkco.com/',
      Icons.business_center_outlined,
    ),
  ];

  Future<void> _abrir(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.parse(url);
    final abierto = await canLaunchUrl(uri) &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!abierto) {
      messenger.showSnackBar(
        SnackBar(content: Text('No pudimos abrir el diagnóstico. Está en ${uri.host}.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.legacyBlue1,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Row(
              children: [
                const BotonVolver(),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Diagnósticos',
                    style: GoogleFonts.barlow(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Identifica riesgos críticos, que podrían comprometer la continuidad del negocio y del legado.',
              style: GoogleFonts.questrial(
                color: const Color(0xFF9FB2C2),
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            for (final d in diagnosticos) ...[
              _boton(context, d),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }

  Widget _boton(BuildContext context, Diagnostico d) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('diagnostico-${d.url}'),
        borderRadius: BorderRadius.circular(14),
        onTap: () => _abrir(context, d.url),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.legacySurface.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.legacyActive.withValues(alpha: 0.5), width: 1.2),
          ),
          child: Row(
            children: [
              Icon(d.icono, color: AppTheme.legacyActive, size: 26),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  d.titulo,
                  style: GoogleFonts.barlow(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.open_in_new, color: AppTheme.legacyActive, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
