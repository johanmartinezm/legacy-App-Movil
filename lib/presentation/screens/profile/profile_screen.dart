import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../widgets/perfil/eliminar_cuenta_dialog.dart';
import '../../../domain/providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final firstName = authProvider.firstName ?? 'Usuario';
    final roleName = authProvider.role ?? authProvider.customerStatus ?? 'Miembro';

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
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          'Mi perfil',
          style: GoogleFonts.barlowCondensed(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF7FB2D9), width: 1.5),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2A5D7D), Color(0xFF123A4F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                firstName,
                style: GoogleFonts.barlowCondensed(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                roleName,
                style: GoogleFonts.questrial(
                  color: const Color(0xFF9FB2C2),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              // Antes de esto, Favoritos solo se alcanzaba desde el menú «⋮»
              // de una pantalla de detalle (Books, Chat, Foros...) — ninguna
              // de las 5 pestañas principales tenía un acceso propio. Quien
              // guardaba un artículo desde el Inicio no tenía forma de volver
              // a encontrarlo sin toparse con ese menú por casualidad. Va de
              // primera en la lista porque es lo que más se usa a diario.
              _buildMenuItem(
                context,
                title: 'Mis favoritos',
                subtitle: 'Artículos y videos guardados',
                onTap: () => context.push('/favorites'),
                icon: Icons.bookmark_outline,
              ),
              const SizedBox(height: 12),

              _buildMenuItem(
                context,
                title: 'Active Legacy+',
                subtitle: 'Comunidad, Red de Gobierno y más',
                icon: Icons.shield_outlined,
                onTap: () => context.push('/legacy-plus'),
                isPremium: true,
              ),
              const SizedBox(height: 12),
              
              _buildMenuItem(
                context,
                title: 'Mi Legacy Test',
                subtitle: 'Próximamente',
                onTap: () {},
                icon: Icons.quiz_outlined,
                isDisabled: true,
              ),
              const SizedBox(height: 12),

              _buildMenuItem(
                context,
                title: 'Mi formación LSO',
                subtitle: 'Explorar programas',
                onTap: () => context.push('/programas'),
                icon: Icons.school_outlined,
              ),
              const SizedBox(height: 12),

              _buildMenuItem(
                context,
                title: 'Mis eventos',
                subtitle: 'Legacy Summit 2026',
                onTap: () => context.go('/home?tab=1'),
                icon: Icons.calendar_today_outlined,
              ),
              const SizedBox(height: 12),

              _buildMenuItem(
                context,
                title: 'Red de Gobierno',
                subtitle: 'Encuentre consejeros',
                onTap: () => context.push('/comunidad-miembros'),
                icon: Icons.groups_outlined,
              ),
              const SizedBox(height: 12),

              _buildMenuItem(
                context,
                title: 'Cambiar tipo de cuenta',
                subtitle: 'Actual: $roleName',
                onTap: () => context.push('/profile-selection'),
                icon: Icons.swap_horiz_outlined,
              ),
              const SizedBox(height: 12),

              _buildMenuItem(
                context,
                title: 'Mi credencial',
                subtitle: 'QR de acceso a eventos',
                onTap: () => context.push('/mi-credencial'),
                icon: Icons.qr_code_outlined,
              ),
              const SizedBox(height: 12),

              _buildMenuItem(
                context,
                title: 'Editar información personal',
                subtitle: 'Actualizar foto, bio y detalles',
                onTap: () => context.push('/profile-edit'),
                icon: Icons.edit_outlined,
              ),
              const SizedBox(height: 12),
              
              _buildMenuItem(
                context,
                title: 'Foros Anónimos',
                subtitle: 'Participa en debates confidenciales',
                onTap: () => context.push('/forums'),
                icon: Icons.forum_outlined,
              ),
              const SizedBox(height: 12),
              
              _buildMenuItem(
                context,
                title: 'Cerrar sesión',
                subtitle: 'Salir de la cuenta en este dispositivo',
                onTap: () async {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) context.go('/login');
                },
                icon: Icons.logout,
                isDestructive: true,
              ),

              const SizedBox(height: 12),

              // El FAQ va antes que Contáctenos a propósito: la mayoría de las
              // dudas ya están respondidas ahí y se resuelven sin esperar.
              _buildMenuItem(
                context,
                title: 'Preguntas frecuentes',
                subtitle: 'Cuenta, comunidad, eventos y privacidad',
                onTap: () => context.push('/faq'),
                icon: Icons.help_outline,
              ),

              _buildMenuItem(
                context,
                title: 'Contáctenos',
                subtitle: 'Escríbenos si necesitas ayuda',
                onTap: () => context.push('/contacto'),
                icon: Icons.support_agent_outlined,
              ),

              // Poder deshacer un bloqueo es lo que hace usable la función:
              // quien bloquea por error no puede encontrar a esa persona por
              // otra vía, porque deja de aparecer en el directorio.
              _buildMenuItem(
                context,
                title: 'Cuentas bloqueadas',
                subtitle: 'Revisa y desbloquea a quien hayas bloqueado',
                onTap: () => context.push('/cuentas-bloqueadas'),
                icon: Icons.block_outlined,
              ),

              // Eliminar la cuenta desde la propia app es requisito de App Store
              // y de Google Play para cualquier app que permita registrarse.
              _buildMenuItem(
                context,
                title: 'Eliminar mi cuenta',
                subtitle: 'Borra tus datos personales de forma permanente',
                onTap: () async {
                  final eliminada = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const EliminarCuentaDialog(),
                  );
                  if (eliminada == true && context.mounted) {
                    context.go('/login');
                  }
                },
                icon: Icons.person_remove_outlined,
                isDestructive: true,
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    IconData? icon,
    bool isPremium = false,
    bool isDestructive = false,
    bool isDisabled = false,
  }) {
    final titleColor = isDestructive ? Colors.redAccent : (isDisabled ? Colors.white.withValues(alpha: 0.4) : Colors.white);
    final subtitleColor = isDestructive ? Colors.redAccent.withValues(alpha: 0.7) : (isDisabled ? const Color(0xFF9FB2C2).withValues(alpha: 0.4) : const Color(0xFF9FB2C2));
    final iconColor = isDestructive ? Colors.redAccent : (isDisabled ? const Color(0xFF7FB2D9).withValues(alpha: 0.4) : const Color(0xFF7FB2D9));
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1A2E).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDestructive ? Colors.redAccent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isPremium ? const Color(0xFF162A3B) : (isDestructive ? Colors.redAccent.withValues(alpha: 0.1) : Colors.transparent),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.barlowCondensed(
                      color: titleColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.questrial(
                      color: subtitleColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isPremium)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF7FB2D9).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/images/Logo.png',
                  height: 16,
                  color: const Color(0xFF7FB2D9),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
