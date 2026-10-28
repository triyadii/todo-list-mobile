import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors - Elegant Executive Palette (No Purple)
  static const Color primary = Color(0xFF0F172A); // Deep Obsidian Slate
  static const Color primaryDark = Color(0xFF020617); // Midnight Void
  static const Color primaryLight = Color(0xFFF1F5F9); // Soft Pearlescent Slate
  static const Color secondary = Color(0xFF2563EB); // Refined Royal Azure
  static const Color accentGold = Color(0xFFD97706); // Champagne Amber Gold

  // Neutral colors - Light Mode
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Colors.white;
  static const Color textMainLight = Color(0xFF0F172A);
  static const Color textMutedLight = Color(0xFF64748B);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Dark Mode Palette - Luxurious Midnight Obsidian
  static const Color backgroundDark = Color(0xFF090D16); // Deep Night Slate
  static const Color surfaceDark = Color(0xFF131B2A); // Rich Slate Card Container
  static const Color surfaceDarkElevated = Color(0xFF1C263A); // Elevated card
  static const Color textMainDark = Color(0xFFF8FAFC); // Crisp Pearlescent White
  static const Color textMutedDark = Color(0xFF94A3B8); // Muted Titanium
  static const Color borderDark = Color(0xFF243045); // Subtle Metallic Border
  static const Color primaryDarkAccent = Color(0xFF38BDF8); // Electric Sky Accent

  // Status colors (Refined & balanced)
  static const Color statusPending = Color(0xFFD97706); // Warm Amber
  static const Color statusInProgress = Color(0xFF0284C7); // Oceanic Blue
  static const Color statusCompleted = Color(0xFF059669); // Emerald Jade
  static const Color statusCancelled = Color(0xFF64748B); // Slate Muted

  // Priority colors
  static const Color priorityLow = Color(0xFF059669); // Emerald
  static const Color priorityMedium = Color(0xFFD97706); // Amber
  static const Color priorityHigh = Color(0xFFDC2626); // Crimson

  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return priorityHigh;
      case 'medium':
        return priorityMedium;
      case 'low':
      default:
        return priorityLow;
    }
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return statusCompleted;
      case 'in_progress':
        return statusInProgress;
      case 'cancelled':
        return statusCancelled;
      case 'pending':
      default:
        return statusPending;
    }
  }

  static String getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Selesai';
      case 'in_progress':
        return 'Sedang Dikerjakan';
      case 'cancelled':
        return 'Dibatalkan';
      case 'pending':
      default:
        return 'Menunggu';
    }
  }

  static String getPriorityLabel(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return 'Tinggi';
      case 'medium':
        return 'Sedang';
      case 'low':
      default:
        return 'Rendah';
    }
  }

  // --- LIGHT THEME ---
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: surfaceLight,
        error: priorityHigh,
        onPrimary: Colors.white,
        onSurface: textMainLight,
        outline: borderLight,
      ),
      textTheme: baseTextTheme.copyWith(
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: textMainLight,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: textMainLight,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: textMainLight,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: textMainLight,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: textMutedLight,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: surfaceLight,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: textMainLight),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: textMainLight,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: surfaceLight,
        elevation: 6,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceLight,
        indicatorColor: primaryLight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: primary,
            );
          }
          return GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: textMutedLight,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: secondary, width: 1.5),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: textMutedLight,
          fontSize: 14,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  // --- DARK THEME ---
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryDarkAccent,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryDarkAccent,
        secondary: secondary,
        surface: surfaceDark,
        error: priorityHigh,
        onPrimary: Color(0xFF0F172A),
        onSurface: textMainDark,
        outline: borderDark,
      ),
      textTheme: baseTextTheme.copyWith(
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: textMainDark,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: textMainDark,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: textMainDark,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: textMainDark,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: textMutedDark,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: surfaceDark,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: textMainDark),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: textMainDark,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderDark, width: 1),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: surfaceDark,
        elevation: 6,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceDark,
        indicatorColor: surfaceDarkElevated,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: primaryDarkAccent,
            );
          }
          return GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: textMutedDark,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: secondary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDarkElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryDarkAccent, width: 1.5),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: textMutedDark,
          fontSize: 14,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
