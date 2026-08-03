import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class MiembrosInfoScreen extends StatelessWidget {
  const MiembrosInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B15),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 14),
          ),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Miembros',
              style: GoogleFonts.barlowCondensed(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            Text(
              'Comunidad del ecosistema Legacy',
              style: GoogleFonts.questrial(
                color: const Color(0xFF9FB2C2),
                fontSize: 12,
              ),
            ),
          ],
        ),
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1A2E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5A93C4).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.asset(
                        'assets/images/Logo.png',
                        height: 24,
                        color: const Color(0xFF7FB2D9),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '¿Qué es Miembros?',
                      style: GoogleFonts.barlowCondensed(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Un espacio reservado para clientes de Legacy Network y alumni del Summit y LSO. No es una red social abierta: es un círculo de confianza entre pares que comparten los mismos retos de gobierno, sucesión y patrimonio.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.questrial(
                        color: const Color(0xFF9FB2C2),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Chats por pilar
              Text(
                'CHATS POR PILAR',
                style: GoogleFonts.barlowCondensed(
                  color: const Color(0xFF7FB2D9),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              _buildPillarItem(
                icon: Icons.people_outline,
                title: 'Familia',
                subtitle: 'Conversaciones, protocolo y relevo generacional',
                onTap: () => context.push('/comunidad-miembros'),
              ),
              const SizedBox(height: 12),
              _buildPillarItem(
                icon: Icons.show_chart,
                title: 'Propiedad o patrimonio',
                subtitle: 'Gestión, inversión y protección del patrimonio',
                onTap: () => context.push('/comunidad-miembros'),
              ),
              const SizedBox(height: 12),
              _buildPillarItem(
                icon: Icons.business_outlined,
                title: 'Empresa',
                subtitle: 'Gobierno corporativo, estrategia y crecimiento',
                onTap: () => context.push('/comunidad-miembros'),
              ),
              
              const SizedBox(height: 32),
              // Además
              Text(
                'ADEMÁS',
                style: GoogleFonts.barlowCondensed(
                  color: const Color(0xFF7FB2D9),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                title: 'Pares de su nivel',
                description: 'Conecte con propietarios, sucesores y consejeros que entienden su realidad.',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                title: 'Acceso a expertos',
                description: 'Sesiones privadas con los expertos del ecosistema (L&M, Aurum, Legacy Legal).',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                title: 'Continuidad post-Summit',
                description: 'El networking del Summit no termina: continúa todo el año aquí.',
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            onPressed: () => context.push('/legacy-plus'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7FB2D9),
              foregroundColor: const Color(0xFF050B15),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Cómo accedo',
              style: GoogleFonts.barlowCondensed(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPillarItem({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1A2E).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF162A3B),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF7FB2D9), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.barlowCondensed(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.questrial(
                    color: const Color(0xFF9FB2C2),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.5), size: 14),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildFeatureItem({required String title, required String description}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF1B4D3E),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Color(0xFF54C6A8), size: 14),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.barlowCondensed(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.questrial(
                  color: const Color(0xFF9FB2C2),
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
