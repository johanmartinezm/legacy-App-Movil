import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/boton_volver.dart';

class LegacyPlusScreen extends StatelessWidget {
  const LegacyPlusScreen({super.key});

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
              Color(0xFF0D253A),
              Color(0xFF061B2B),
              Color(0xFF03070E),
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
                              color: const Color(0xFF90A4BA),
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
                              const Color(0xFF0F2036).withValues(alpha: 0.95),
                              const Color(0xFF081220).withValues(alpha: 0.95),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFD9A74A).withValues(alpha: 0.25),
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
                                    Color(0xFFE8DCCA),
                                    Color(0xFFCAA24F),
                                    Color(0xFF9A7B30),
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
                                    color: const Color(0xFF050B15),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              '¿Qué es Legacy+?',
                              style: GoogleFonts.barlowCondensed(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Es el acceso completo a la comunidad privada, la Red de Gobierno, los programas LSO con precio especial y el contenido reservado de Legacy Network.',
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
                      const SizedBox(height: 28),

                      // SECTION 1: YA TIENE LEGACY+ SI ES...
                      Text(
                        'YA TIENE LEGACY+ SI ES...',
                        style: GoogleFonts.barlow(
                          color: const Color(0xFFD9A74A),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildCheckItem(
                        'Cliente de una unidad',
                        'L&M, Aurum Legacy Advisors, Legacy Legal o Network en Gobierno Corporativo.',
                      ),
                      const SizedBox(height: 16),
                      _buildCheckItem(
                        'Alumni del Legacy Summit',
                        'Quienes han asistido al Summit acceden a la comunidad y descuentos.',
                      ),
                      const SizedBox(height: 16),
                      _buildCheckItem(
                        'Alumni de LSO',
                        'Egresados de cualquier programa de la escuela.',
                      ),
                      const SizedBox(height: 32),

                      // SECTION 2: SI AÚN NO ES CLIENTE NI ALUMNI
                      Text(
                        'SI AÚN NO ES CLIENTE NI ALUMNI',
                        style: GoogleFonts.barlow(
                          color: const Color(0xFFD9A74A),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Price box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B1A2E).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFD9A74A).withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: GoogleFonts.barlow(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                children: [
                                  const TextSpan(
                                    text: 'COP 1.790.000 ',
                                    style: TextStyle(color: Color(0xFFD9A74A)),
                                  ),
                                  TextSpan(
                                    text: '/ año',
                                    style: GoogleFonts.questrial(
                                      color: const Color(0xFF90A4BA),
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'O su equivalente en USD según la TRM del día. Acceso a comunidad, Red de Gobierno (4 búsquedas incluidas) y contenido Legacy+.',
                              style: GoogleFonts.questrial(
                                color: const Color(0xFFE8EEF5).withValues(alpha: 0.85),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Benefits check items
                      _buildCheckItem(
                        'Comunidad privada',
                        'Networking de confianza con pares y expertos.',
                      ),
                      const SizedBox(height: 16),
                      _buildCheckItem(
                        'Red de Gobierno · 4 búsquedas',
                        'Matching de consejeros incluido; resto a precio especial.',
                      ),
                      const SizedBox(height: 16),
                      _buildCheckItem(
                        'Legacy Knowledge completo',
                        'Contenido reservado y biblioteca ejecutiva.',
                      ),
                      const SizedBox(height: 16),
                      _buildCheckItem(
                        'Programas LSO con precio especial',
                        'Descuento en toda la escuela.',
                      ),
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
                  color: const Color(0xFF90A4BA),
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
