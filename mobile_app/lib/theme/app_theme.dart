import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Glow & Accent Colors
  static const Color primaryColor = Color(0xFF6366F1); // Radiant Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color secondaryColor = Color(0xFF8B5CF6); // Neon Purple
  static const Color accentCyan = Color(0xFF06B6D4); // Cyber Cyan
  
  // Status Glow Colors
  static const Color spamRed = Color(0xFFF43F5E); // Vibrant Rose/Red
  static const Color spamRedGlow = Color(0x33F43F5E);
  static const Color hamGreen = Color(0xFF10B981); // Emerald Green
  static const Color hamGreenGlow = Color(0x3310B981);
  static const Color warningOrange = Color(0xFFF59E0B); // Amber Accent
  
  // Dark Glassmorphic Neutrals
  static const Color bgDark = Color(0xFF090D16); // Deepest Obsidian
  static const Color bgDarkSecondary = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF151C2C); // Dark Slate Surface
  static const Color cardDark = Color(0xFF1E293B); // Elevated Card Surface
  static const Color borderDark = Color(0xFF334155); // Crisp Subtle Border
  static const Color borderGlow = Color(0xFF475569);
  
  // Text & Content Hierarchy
  static const Color textLight = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDim = Color(0xFF64748B);

  static ThemeData get darkTheme {
    final baseTextTheme = ThemeData.dark().textTheme;
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: bgDark,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceDark,
        error: spamRed,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        baseTextTheme.apply(
          bodyColor: textLight,
          displayColor: textLight,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textLight,
        ),
      ),
      cardTheme: CardTheme(
        color: surfaceDark,
        elevation: 6,
        shadowColor: Colors.black.withOpacity(0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: borderDark, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        hintStyle: TextStyle(color: textMuted.withOpacity(0.6), fontSize: 14),
        contentPadding: const EdgeInsets.all(20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: borderDark, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: borderDark, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: primaryColor.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

