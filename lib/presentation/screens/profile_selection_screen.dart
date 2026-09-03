import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/boton_volver.dart';

class ProfileSelectionScreen extends StatelessWidget {
  const ProfileSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1A2E), // Dark blue from the image
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BotonVolver(destino: '/login'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // Logo
              Image.asset(
                'assets/images/Logo.png',
                height: 80,
                width: 80,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.account_balance,
                    color: Colors.white,
                    size: 80,
                  );
                },
              ),
              const SizedBox(height: 24),
              // Welcome Text
              const Text(
                'Bienvenido a\nLegacy Network',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              // Subtitle
              const Text(
                'Para personalizar su experiencia, cuéntenos quién es. Podrá cambiarlo después.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 40),

              // Options
              _ProfileOptionCard(
                icon: Icons.people_alt_outlined,
                title: 'Soy una familia empresaria',
                subtitle:
                    'Fortalecer legado, patrimonio, sucesión y continuidad.',
                onTap: () {
                  context.push('/register?role=familia');
                },
              ),
              const SizedBox(height: 16),
              _ProfileOptionCard(
                icon: Icons.business_outlined,
                title: 'Represento una empresa',
                subtitle:
                    'Crear, mejorar o certificar el gobierno corporativo.',
                onTap: () {
                  context.push('/register?role=empresa');
                },
              ),
              const SizedBox(height: 16),
              _ProfileOptionCard(
                icon: Icons.person_outline,
                title: 'Quiero ser miembro de junta o consejo',
                subtitle: 'Postular a la Red de Gobierno de Legacy Network.',
                onTap: () {
                  context.push('/register?role=junta');
                },
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
