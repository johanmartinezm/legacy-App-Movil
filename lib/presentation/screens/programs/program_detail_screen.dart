import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../domain/models/program_model.dart';
import '../../widgets/boton_volver.dart';

class ProgramDetailScreen extends StatelessWidget {
  final GraphqlProgram program;

  const ProgramDetailScreen({super.key, required this.program});

  Future<void> _launchWhatsApp() async {
    final String message = 'Hola, me interesa el programa LSO: ${program.name}';
    final String url = 'https://wa.me/573000000000?text=${Uri.encodeComponent(message)}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  /// Lleva a la pagina del programa en la tienda de LSO.
  ///
  /// La inscripcion se hace alli y no en la app —decision del 2026-08-19—:
  /// los programas son de LSO, se cobran en dolares y tienen su propio
  /// proceso. Antes esto metia el programa al carrito, que sumaba esos
  /// dolares como si fueran pesos y les aplicaba IVA colombiano.
  Future<void> _abrirEnLso(BuildContext context) async {
    final enlace = program.url;
    final messenger = ScaffoldMessenger.of(context);

    bool abierto = false;
    if (enlace != null) {
      final uri = Uri.parse(enlace);
      // Fuera de la app a proposito: la inscripcion pide cuenta en LSO y
      // medios de pago que la app no tiene.
      abierto = await canLaunchUrl(uri) &&
          await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    // Un toque sin respuesta parece que la app se colgo. Si no se pudo abrir
    // se dice, con el nombre del sitio para que se pueda buscar a mano.
    if (!abierto) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No pudimos abrir la página del programa. Está en lso.school.'),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B15),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.8, -0.8),
            radius: 1.5,
            colors: [
              Color(0xFF13304A),
              Color(0xFF0E2C3B),
              Color(0xFF050B15),
            ],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Botón Atrás Superior ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: const BotonVolver(destino: '/programas'),
              ),

              // ── Contenido Principal Desplazable ──────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icono de Gorro de Graduación Circular
                      Center(
                        child: Container(
                          width: 90,
                          height: 90,
                          margin: const EdgeInsets.only(top: 10, bottom: 24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0B1A2E).withValues(alpha: 0.8),
                            border: Border.all(
                              color: const Color(0xFF2A4A75).withValues(alpha: 0.35),
                              width: 1.5,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.school_outlined,
                              color: Color(0xFF5A93C4),
                              size: 40,
                            ),
                          ),
                        ),
                      ),

                      // Título del Programa
                      Text(
                        program.name,
                        style: GoogleFonts.barlow(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Subtítulo con Certificación
                      Text(
                        program.shortDescription ?? '🎓 LSO · Doble certificación LSO + EUDE',
                        style: GoogleFonts.questrial(
                          fontSize: 14,
                          color: const Color(0xFF90A4BA),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Descripción del Programa
                      Text(
                        program.description ?? '',
                        style: GoogleFonts.questrial(
                          fontSize: 14.5,
                          color: const Color(0xFFE8EEF5),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Ficha Técnica (Formato, Duración, Tipo)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B1A2E).withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF2A4A75).withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow('Formato', program.modality),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(color: Color(0xFF1E3A5F), height: 1, thickness: 1),
                            ),
                            _buildInfoRow('Duración', program.duration),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(color: Color(0xFF1E3A5F), height: 1, thickness: 1),
                            ),
                            _buildInfoRow('Tipo', program.type),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Alerta Promocional (Legacy+)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D282D).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF00F2FE).withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Text.rich(
                          TextSpan(
                            text: 'Clientes Legacy Network y alumni acceden a Legacy+ con ',
                            style: GoogleFonts.questrial(
                              color: const Color(0xFF00F2FE),
                              fontSize: 13,
                              height: 1.4,
                            ),
                            children: [
                              TextSpan(
                                text: 'precio especial',
                                style: GoogleFonts.questrial(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const TextSpan(text: ' en programas.'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Botón Inscribirme (Dorado). Lleva a LSO: la
                      // inscripción no ocurre dentro de la app.
                      ElevatedButton(
                        onPressed: () => _abrirEnLso(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD9A74A),
                          foregroundColor: const Color(0xFF050B15),
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Inscribirme en LSO',
                          style: GoogleFonts.barlow(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Botón Hablar con Asesor (Delineado)
                      OutlinedButton(
                        onPressed: _launchWhatsApp,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: const Color(0xFF1E3A5F).withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Hablar con un asesor',
                          style: GoogleFonts.barlow(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.questrial(
            color: const Color(0xFF90A4BA),
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.questrial(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
