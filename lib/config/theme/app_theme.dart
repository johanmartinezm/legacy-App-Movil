import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Paleta de marca — Manual de Imagen LEGACY Network (julio 2023)
  // Los tres azules y el negro son los valores normativos del manual; los dos
  // pasteles se toman del logo oficial (Log_LegNet-abierto.ai), que el manual
  // ilustra pero no publica en hexadecimal.
  static const Color legacyBlue1 = Color(0xFF162540); // Azul No.1 — fondo
  static const Color legacyBlue2 = Color(0xFF183D6B); // Azul No.2 — paneles y acento
  static const Color legacyBlue3 = Color(0xFF306C9E); // Azul No.3 — matiz de transicion
  static const Color legacyBlue4 = Color(0xFF70ABE0); // Azul No.4 — pastel
  static const Color legacyBlue5 = Color(0xFF8AC6FB); // Azul No.5 — pastel claro

  // Escalon de apoyo: mezcla al 50% de Azul No.1 y Azul No.2. No es normativo,
  // existe porque una interfaz oscura necesita un nivel entre fondo y panel.
  static const Color legacySurface = Color(0xFF1B3156);

  static const Color legacyWhite = Color(0xFFE8EEF5); // Light text color (replacing pure white)
  static const Color legacyBlack = Color(0xFF000000);

  static const Color legacyGrey = Color(0xFF183D6B); // Adjusted for consistent dark base

  // Secondary Palette (accents)
  static const Color legacyGold = Color(0xFF8AC6FB); // Replaced gold accent with steel-blue as per spec
  static const Color legacyGreen = Color(0xFF2F9E6B); 
  static const Color legacyGreenLight = Color(0xFF1B3D2F); 
  static const Color legacyGreenDark = Color(0xFF54C6A8); 
  static const Color legacyRed = Color(0xFF771515); // Rojo del manual
  static const Color legacyOrange = Color(0xFF8AC6FB); 

  static const List<String> emojiFallbacks = [
    'Apple Color Emoji',
    'Segoe UI Emoji',
    'Noto Color Emoji',
    'Android Emoji',
    'EmojiSymbols',
  ];

  static ThemeData get lightTheme {
    return _buildTheme(Brightness.dark); // Force dark theme by default
  }

  static ThemeData get darkTheme {
    return _buildTheme(Brightness.dark);
  }

  static ThemeData _buildTheme(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: legacyBlue4,
        secondary: legacyBlue3,
        tertiary: legacyBlue5,
        surface: legacyBlue2,
        onSurface: legacyWhite,
        error: Colors.redAccent,
      ),
      scaffoldBackgroundColor: legacyBlue1,
      
      // Typography
      textTheme: TextTheme(
        displayLarge: GoogleFonts.barlow(
          fontWeight: FontWeight.bold,
          color: legacyWhite,
        ),
        displayMedium: GoogleFonts.barlow(
          fontWeight: FontWeight.bold,
          color: legacyWhite,
        ),
        displaySmall: GoogleFonts.barlow(
          fontWeight: FontWeight.w600,
          color: legacyWhite,
        ),
        headlineMedium: GoogleFonts.barlow(
          fontWeight: FontWeight.w600,
          color: legacyWhite,
        ),
        headlineSmall: GoogleFonts.barlow(
          fontWeight: FontWeight.w500,
          color: legacyWhite,
        ),
        titleLarge: GoogleFonts.barlow(
          fontWeight: FontWeight.w600,
          color: legacyWhite,
        ),
        bodyLarge: GoogleFonts.questrial(
          color: legacyWhite,
        ),
        bodyMedium: GoogleFonts.questrial(
          color: legacyWhite.withValues(alpha: 0.8),
        ),
        labelLarge: GoogleFonts.questrial(
          fontWeight: FontWeight.bold,
          color: legacyWhite,
        ),
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: Colors.white12, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: Colors.white12, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: legacyBlue4, width: 1.5),
        ),
        labelStyle: GoogleFonts.questrial(color: legacyWhite.withValues(alpha: 0.6)),
        hintStyle: GoogleFonts.questrial(color: legacyWhite.withValues(alpha: 0.4)),
      ),
      
      // ElevatedButton Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: legacyBlue3,
          foregroundColor: legacyWhite,
          textStyle: GoogleFonts.questrial(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // TextButton Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: legacyBlue5,
          textStyle: GoogleFonts.questrial(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return legacyBlue4;
          }
          return null;
        }),
        checkColor: WidgetStateProperty.all(legacyBlue1),
        side: const BorderSide(color: Colors.white24, width: 1.5),
      ),
    );
  }
}
