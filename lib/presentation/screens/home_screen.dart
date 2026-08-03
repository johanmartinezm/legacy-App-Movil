import 'package:flutter/material.dart';

import 'informandote/informandote_screen.dart';
import 'eventos/eventos_screen.dart';
import 'home/home_content_screen.dart';
import 'comunidad/comunidad_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex) {
      setState(() {
        _selectedIndex = widget.initialIndex;
      });
    }
  }

  static const List<Widget> _widgetOptions = <Widget>[
    HomeContentScreen(),
    EventosScreen(),
    ComunidadScreen(),
    InformandoteScreen(), // "Noticias"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
    );
  }
}
