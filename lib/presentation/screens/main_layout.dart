import 'package:flutter/material.dart';
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

    if (location.startsWith('/legacy-plus') || location.startsWith('/programas') || location.startsWith('/programa-detalle')) {
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

  @override
  Widget build(BuildContext context) {
    final int selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white10,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF0B1A2E), // Premium dark theme blue-gray
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
              label: 'CONOCER',
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
          selectedItemColor: const Color(0xFFD9A74A), // Selected tab is Premium Gold
          unselectedItemColor: const Color(0xFF90A4BA), // Unselected is steel blue/gray
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: GoogleFonts.barlow(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: GoogleFonts.questrial(
            fontSize: 11,
            letterSpacing: 0.5,
          ),
          onTap: (index) => _onItemTapped(index, context),
        ),
      ),
    );
  }
}
