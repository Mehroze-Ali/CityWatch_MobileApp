import 'package:flutter/material.dart';

class AppTheme {
  // Module A Colors - Dark Urban Glassmorphism
  static const Color darkBackground = Color(0xFF0A0A0A);
  static const Color cardWhite = Color(0xFFFAFAFA);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGrey = Color(0xFF8E8E8E);
  static const Color textLightGrey = Color(0xFFB0B0B0);
  static const Color buttonBlack = Color(0xFF1A1A1A);
  static const Color accentBlue = Color(0xFF4A90E2);

  // Module B Colors - Primary Teal/Blue (Trust & Stability)
  static const Color primaryTealDark = Color(0xFF032A33);
  static const Color primaryTeal = Color(0xFF0B4B54);
  static const Color primaryTealMedium = Color(0xFF2A777C);
  static const Color primaryTealLight = Color(0xFF82ACAB);
  static const Color primaryTealLightest = Color(0xFFD3E4E7);

  // Module B Colors - Blue Shades
  static const Color navyBlue = Color(0xFF001B48);
  static const Color royalBlue = Color(0xFF02457A);
  static const Color cyanBlue = Color(0xFF018ABE);
  static const Color lightBlue = Color(0xFF97CADB);
  static const Color paleBlue = Color(0xFFD6E8EE);

  // Module B Colors - Accent (Issues & Alerts)
  static const Color alertRed = Color(0xFFD74243);
  static const Color warningOrange = Color(0xFFFC6A4A);
  static const Color lightNeutral = Color(0xFFEFECE4);
  static const Color mediumGrey = Color(0xFF5B5F57);
  static const Color darkGrey = Color(0xFF202020);

  // Status Colors
  static const Color statusPending = Color(0xFFFFA726); // Orange
  static const Color statusResolved = Color(0xFF66BB6A); // Green

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: darkBackground,
      fontFamily: 'SF Pro Display',

      textTheme: const TextTheme(
        // Large display text - "Your next adventure awaits you"
        displayLarge: TextStyle(
          fontSize: 38,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1.15,
          letterSpacing: -0.5,
        ),
        // Headlines - "Welcome.", "Explore."
        headlineLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: textDark,
          letterSpacing: -0.5,
        ),
        // Onboarding titles - "Snap & Report"
        headlineMedium: TextStyle(
          fontSize: 38,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1.2,
          letterSpacing: -0.5,
        ),
        // Brand name - "ventūr"
        titleLarge: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 1.5,
        ),
        // Body text
        bodyLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: textGrey,
          height: 1.5,
          letterSpacing: 0,
        ),
        // Small text - labels
        bodySmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textGrey,
          letterSpacing: 0.2,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonBlack,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentBlue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: const TextStyle(
          color: textLightGrey,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: Colors.grey[400]!, width: 1.5),
      ),
    );
  }
}
