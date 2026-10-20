import 'package:flutter/material.dart';

class AppTheme {
  // Cores do Design System
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundSurface = Color(0xFFF8F9FA);
  static const Color primaryEmerald = Color(0xFF00A884);
  static const Color primaryDark = Color(0xFF008065);
  static const Color primaryLight = Color(0xFFE8F7F3);
  static const Color darkGraphite = Color(0xFF3D3D3D);
  static const Color textMuted = Color(0xFF757575);
  static const Color borderSubtle = Color(0xFFE0E0E0);
  static const Color borderActive = Color(0xFFB0BEC5);

  // Status & Severidade
  static const Color severityLowBg = Color(0xFFE8F5E9);
  static const Color severityLowText = Color(0xFF2E7D32);
  static const Color severityMediumBg = Color(0xFFFFF8E1);
  static const Color severityMediumText = Color(0xFFF57F17);
  static const Color severityHighBg = Color(0xFFFFEBEE);
  static const Color severityHighText = Color(0xFFC62828);

  // Badges de Rota
  static const Color localBadgeBg = Color(0xFFE0F2F1);
  static const Color localBadgeText = Color(0xFF00695C);
  static const Color cloudBadgeBg = Color(0xFFEDE7F6);
  static const Color cloudBadgeText = Color(0xFF512DA8);
  static const Color cacheBadgeBg = Color(0xFFFFF3E0);
  static const Color cacheBadgeText = Color(0xFFE65100);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundWhite,
      colorScheme: const ColorScheme.light(
        primary: primaryEmerald,
        onPrimary: Colors.white,
        secondary: darkGraphite,
        onSecondary: Colors.white,
        surface: backgroundSurface,
        onSurface: darkGraphite,
        outline: borderSubtle,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: darkGraphite),
        titleTextStyle: TextStyle(
          color: darkGraphite,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: backgroundWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryEmerald, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryEmerald,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
