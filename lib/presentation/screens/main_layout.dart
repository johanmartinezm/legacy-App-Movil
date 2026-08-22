import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final state = GoRouterState.of(context);
    final String location = state.uri.path;

    if (location.startsWith('/home')) {
      final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;
      if (tab == 0) return 0; // INICIO
      if (tab == 1) return 2; // EVENTOS
      return 0;
    }

    if (location.startsWith('/informandote') ||
        location.startsWith('/article-detail') ||
        location.startsWith('/video-detail')) {
      return 1; // CONOCER
    }

    if (location.startsWith('/eventos')) {
      return 2; // EVENTOS
    }

    if (location.startsWith('/legacy-plus') ||
        location.startsWith('/programas') ||
        location.startsWith('/programa-detalle')) {
      return 3; // LEGACY+
    }

    if (location.startsWith('/profile')) {
      return 4; // PERFIL
    }

    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/informandote');
        break;
      case 2:
        context.go('/home?tab=1'); // EVENTOS
        break;
      case 3:
        context.go('/legacy-plus'); // LEGACY+
        break;
      case 4:
        context.go('/profile'); // PERFIL
        break;
    }
  }

  Future<void> _confirmarSalida(BuildContext context) async {
    final salir = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0B1A2E),
        title: Text(
          '¿Salir de Legacy Network?',
          style: GoogleFonts.barlow(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: Text(
          'Vas a cerrar la aplicación.',
          style: GoogleFonts.questrial(color: Colors.white70),
        ),
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
    if (salir == true) {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final int selectedIndex = _calculateSelectedIndex(context);

    return PopScope(
      // Solo se pregunta al salir desde Inicio, que es la raíz: en las demás
      // pestañas la flecha de atrás tiene a dónde volver dentro de la app.
      canPop: selectedIndex != 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmarSalida(context);
      },
      child: Scaffold(
        body: child,
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.white10, width: 1)),
          ),
          child: BottomNavigationBar(
            backgroundColor: const Color(
              0xFF0B1A2E,
            ), // Premium dark theme blue-gray
            elevation: 0,
            items: <BottomNavigationBarItem>[
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'INICIO',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.menu_book_outlined),
                activeIcon: Icon(Icons.menu_book),
                // La seccion se llama «Legacy Knowledge» en el home, el menu
                // lateral, su encabezado y Legacy Plus. Aqui decia «CONOCER»
                // hasta el 2026-08-20: se pulsaba una cosa y se aterrizaba en
                // otra, que es lo que hacia pensar que eran dos sitios. Se deja
                // la mitad que identifica la seccion; «LEGACY» a secas chocaria
                // con la pestaña LEGACY+.
                label: 'KNOWLEDGE',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_outlined),
                activeIcon: Icon(Icons.calendar_today),
                label: 'EVENTOS',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(bottom: 2.0),
                  child: Image.asset(
                    'assets/images/Logo.png',
                    height: 18,
                    width: 18,
                    color: const Color(0xFF90A4BA),
                  ),
                ),
                activeIcon: Padding(
                  padding: const EdgeInsets.only(bottom: 2.0),
                  child: Image.asset(
                    'assets/images/Logo.png',
                    height: 18,
                    width: 18,
                    color: const Color(0xFFD9A74A),
                  ),
                ),
                label: 'LEGACY+',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'PERFIL',
              ),
            ],
            currentIndex: selectedIndex,
            selectedItemColor: const Color(
              0xFFD9A74A,
            ), // Selected tab is Premium Gold
            unselectedItemColor: const Color(
              0xFF90A4BA,
            ), // Unselected is steel blue/gray
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            // 10 y sin apenas espaciado porque «KNOWLEDGE» es la etiqueta mas
            // larga de la barra —nueve caracteres frente a los seis o siete de
            // las demas— y a 11 con 0.5 se cortaba en «KNOWLED...». Se baja para
            // las cinco y no solo para esa: BottomNavigationBar aplica un unico
            // estilo, y desigualarlas a mano se veria peor que el recorte.
            selectedLabelStyle: GoogleFonts.barlow(
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 0.1,
            ),
            unselectedLabelStyle: GoogleFonts.questrial(
              fontSize: 10,
              letterSpacing: 0.1,
            ),
            onTap: (index) => _onItemTapped(index, context),
          ),
        ),
      ),
    );
  }
}
