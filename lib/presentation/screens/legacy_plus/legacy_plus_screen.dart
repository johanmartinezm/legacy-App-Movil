import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/boton_volver.dart';
import 'package:legacy_app/config/theme/app_theme.dart';

class LegacyPlusScreen extends StatelessWidget {
  const LegacyPlusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF162540),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.8, -0.8),
            radius: 1.5,
            colors: [
              Color(0xFF1B3156),
              Color(0xFF162540),
              Color(0xFF162540),
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Header / AppBar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    const BotonVolver(),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Legacy+',
                            style: GoogleFonts.barlow(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'El acceso completo al ecosistema',
                            style: GoogleFonts.questrial(
                              fontSize: 13,
                              color: const Color(0xFF9FB2C2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Main content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Featured Top Info Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF1B3156).withValues(alpha: 0.95),
                              const Color(0xFF081220).withValues(alpha: 0.95),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.legacyActive.withValues(alpha: 0.25),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Gold L Logo Square
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.legacyBlue5,
                                    AppTheme.legacyActive,
                                    AppTheme.legacyBlue3,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'L',
                                  style: GoogleFonts.barlow(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF162540),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Título y texto del cliente, 2026-10-13. Antes:
                            // «¿Qué es Legacy+?» y, ese mismo día, «Cómo accedo:
                            // debes ser cliente de alguna unidad…».
                            Text(
                              'LEGACY+',
                              style: GoogleFonts.barlowCondensed(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Servicios y beneficios plus para los clientes de Legacy Network o Alumni LSO',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.questrial(
                                color: const Color(0xFFE8EEF5).withValues(alpha: 0.9),
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Texto del cliente bajo el banner, 2026-10-13.
                      Text(
                        'Cómo accedo: debes ser cliente de alguna unidad de negocio o ser alumni de LSO. Tiene acceso a:',
                        key: const Key('legacy-plus-como-accedo'),
                        style: GoogleFonts.questrial(
                          color: const Color(0xFFE8EEF5).withValues(alpha: 0.9),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Lo que incluye y los beneficios: textos del cliente,
                      // 2026-10-13. Los tres primeros son las filas de la
                      // sección Legacy+ del Inicio.
                      _buildCheckItem(
                        'Chats de sinergia',
                        'Chats de sinergia entre pares: hay 4 chats para hablar de temas de Empresa, Patrimonio, Familia y otros entre miembros de otras familias empresarias.',
                      ),
                      const SizedBox(height: 16),
                      _buildCheckItem(
                        'Legacy Board',
                        'Red de gobierno corporativo que conecta a familias empresarias y empresas que necesitan crear o fortalecer sus órganos de gobierno (juntas directivas, consejos de familia, directorios, advisory boards y comités) con profesionales que quieren servir en ellos.',
                      ),
                      const SizedBox(height: 16),
                      _buildCheckItem(
                        'Beneficios',
                        'Son descuentos y servicios especiales de aliados o de Legacy Network.',
                      ),
                      const SizedBox(height: 28),

                      Text(
                        'BENEFICIOS',
                        style: GoogleFonts.barlow(
                          color: AppTheme.legacyActive,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildCheckItem(
                        'Legacy Network',
                        'Legacy Test con descuento. Legacy Test: trampas familiares bonificado. Descuento LSO 15% para cualquier programa, 10% de descuento en los libros en nuestra página con el código xxxx. 20% de descuento en el Legacy Summit.',
                      ),
                      const SizedBox(height: 16),
                      _buildCheckItem(
                        'Beneficios de aliados',
                        'Vitalea, Olfabrand, Boconcept, Espectador, EUDE, JW Marriott.',
                      ),
                      // Hasta aquí llega la pantalla desde el 2026-10-13: el
                      // cliente retiró «YA TIENE LEGACY+ SI ES…», el precio
                      // (COP 1.790.000 / año) y la lista anterior de lo que
                      // incluía.
                      const SizedBox(height: 20),
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

  Widget _buildCheckItem(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Green Check Icon
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFF0F2F20),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.check,
              color: Color(0xFF2ECC71),
              size: 14,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Title and description
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.barlow(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.questrial(
                  fontSize: 13,
                  color: const Color(0xFF9FB2C2),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
