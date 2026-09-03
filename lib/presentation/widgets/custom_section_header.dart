import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../domain/providers/auth_provider.dart';
import '../../config/theme/app_theme.dart';
import 'boton_volver.dart';

class CustomSectionHeader extends StatelessWidget {
  /// El nombre de la pantalla, bajo el logotipo. Va en mayúsculas, como el
  /// resto de encabezados.
  ///
  /// Desde el 2026-08-20 **se pinta**: sustituye a «Network®» en la segunda
  /// línea del bloque de marca. Antes se declaraba obligatorio y no se
  /// mostraba, así que las diez pantallas que usan este widget se veían
  /// idénticas y ninguna decía dónde estabas.
  ///
  /// Vacío deja «Network®», que es lo que había antes.
  final String title;
  final bool showDescriptionToggle;
  final bool isDescriptionOpen;
  final bool showBackButton;
  final VoidCallback? onDescriptionToggle;

  /// Acción opcional al final del encabezado. La usa la pantalla de chat para
  /// el menú de reportar y bloquear, que la directriz 1.2 de Apple pide tener
  /// donde ocurre el contacto. Es opcional para no alterar el resto de
  /// pantallas que ya usan este encabezado.
  final Widget? trailing;

  const CustomSectionHeader({
    super.key,
    required this.title,
    this.showDescriptionToggle = false,
    this.isDescriptionOpen = false,
    this.showBackButton = false,
    this.onDescriptionToggle,
    this.trailing,
  });

  void _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      if (!context.mounted) return;
      Provider.of<AuthProvider>(context, listen: false).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gradient de azul marino oscuro (centro hacia extremos) - Prototipo v3
    final headerGradient = LinearGradient(
      colors: [AppTheme.legacyBlue1, AppTheme.legacyBlue2, AppTheme.legacyBlue1],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    return Container(
      decoration: BoxDecoration(gradient: headerGradient),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Left: back / toggle / menu dots
          if (showBackButton)
            const BotonVolver()
          else if (showDescriptionToggle)
            GestureDetector(
              onTap: onDescriptionToggle,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF306C9E),
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.all(4),
                child: Icon(
                  isDescriptionOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
              tooltip: 'Menú',
              onSelected: (value) {
                switch (value) {
                  case 'profile':
                    context.push('/profile');
                    break;
                  case 'favorites':
                    context.push('/favorites');
                    break;
                  case 'about':
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Acerca de esta app'),
                        content: const Text(
                          'Legacy Network v1.0.0\n\nPlataforma para familias empresarias.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cerrar'),
                          ),
                        ],
                      ),
                    );
                    break;
                  case 'legal':
                    context.push('/legal-notice');
                    break;
                  case 'logout':
                    _confirmLogout(context);
                    break;
                  case 'sec_home':
                    context.go('/home?tab=0');
                    break;
                  case 'sec_info':
                    context.go('/home?tab=3');
                    break;
                  case 'sec_event':
                    context.go('/home?tab=1');
                    break;
                  case 'sec_comunidad':
                    context.go('/home?tab=2');
                    break;
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'profile',
                  child: ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Mi perfil'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'favorites',
                  child: ListTile(
                    leading: Icon(Icons.bookmark_outline),
                    title: Text('Artículos guardados'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'about',
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Acerca de esta app'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'legal',
                  child: ListTile(
                    leading: Icon(Icons.policy),
                    title: Text('Políticas y condiciones'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  enabled: false,
                  child: Text(
                    'SECCIONES',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'sec_home',
                  child: ListTile(leading: Icon(Icons.home_outlined), title: Text('Inicio'), contentPadding: EdgeInsets.zero),
                ),
                const PopupMenuItem<String>(
                  value: 'sec_info',
                  child: ListTile(leading: Icon(Icons.article_outlined), title: Text('Legacy Knowledge'), contentPadding: EdgeInsets.zero),
                ),
                const PopupMenuItem<String>(
                  value: 'sec_event',
                  child: ListTile(leading: Icon(Icons.calendar_month_outlined), title: Text('Eventos'), contentPadding: EdgeInsets.zero),
                ),
                const PopupMenuItem<String>(
                  value: 'sec_comunidad',
                  child: ListTile(leading: Icon(Icons.groups_outlined), title: Text('Comunidad'), contentPadding: EdgeInsets.zero),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.exit_to_app, color: Colors.red),
                    title: Text('Salir', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),

          // Center: LEGACY Network — tipografía fiel al banner_logo.jpg
          // LEGACY: Playfair Display Bold (serif elegante, crema cálida)
          // Network®: Questrial Regular (sans-serif limpio, ya en uso en el proyecto)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'LEGACY',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      // Color crema cálida idéntico al banner_logo.jpg
                      color: const Color(0xFFE8DCCA),
                      letterSpacing: 1.0,
                    ),
                  ),
                  // La segunda línea dice DÓNDE estás; «Network®» solo
                  // cuando la pantalla no da nombre. Hasta el 2026-08-20 aquí
                  // iba siempre la marca, así que las diez pantallas que usan
                  // este encabezado se veían idénticas y ninguna se
                  // identificaba: el nombre que cada una pasaba en `title` no
                  // se pintaba en ninguna parte.
                  //
                  // «LEGACY» se queda: es la mitad que reconoce la marca, y
                  // perderla en las pantallas interiores sería peor que
                  // repetir «Network®» diez veces.
                  Text(
                    title.trim().isEmpty ? 'Network®' : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.questrial(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.85),
                      // Menos espaciado que el «Network®» que sustituye:
                      // «MIEMBROS DE LA COMUNIDAD» son 24 caracteres y a 1.5
                      // se acercaba demasiado a los iconos.
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right: Notification bell + circular profile avatar
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailing != null) trailing!,
              // Notification bell
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
                tooltip: 'Notificaciones',
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              const SizedBox(width: 4),
              // Circular profile avatar
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: const Icon(Icons.person, color: Color(0xFF183D6B), size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
