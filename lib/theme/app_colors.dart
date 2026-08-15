import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Color palette and design tokens for ReserveHub.
/// Import this file for raw color values.
/// Use [AppTheme] for full ThemeData objects.
class AppColors {
  AppColors._();

  // ─── Brand ─────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1A1A2E);
  static const Color primaryLight = Color(0xFF2D2D4E);
  static const Color secondary = Color(0xFF4A90D9);
  static const Color secondaryContainer = Color(0xFFDCEEFB);
  static const Color accent = Color(0xFFF5C518);

  // ─── Semantic ──────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2D7A4F);
  static const Color successContainer = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFB45309);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFB91C1C);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0369A1);
  static const Color infoContainer = Color(0xFFE0F2FE);

  // ─── Light surfaces ────────────────────────────────────────────────────────
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF8F9FA);
  static const Color backgroundLight = Color(0xFFF4F5F7);
  static const Color outlineLight = Color(0xFFE2E8F0);
  static const Color outlineVariantLight = Color(0xFFF1F5F9);
  static const Color onSurfaceLight = Color(0xFF0F172A);
  static const Color onSurfaceVariantLight = Color(0xFF64748B);

  // ─── Dark surfaces ─────────────────────────────────────────────────────────
  static const Color surfaceDark = Color(0xFF1E1E2E);
  static const Color surfaceVariantDark = Color(0xFF2A2A3E);
  static const Color backgroundDark = Color(0xFF12121E);
  static const Color onSurfaceDark = Color(0xFFE6E6E6);
  static const Color onSurfaceVariantDark = Color(0xFF94A3B8);

  // ─── Loyalty tier colors ───────────────────────────────────────────────────
  static const Color tierBronze = Color(0xFFCD7F32);
  static const Color tierBronzeContainer = Color(0xFFFDF0E0);
  static const Color tierSilver = Color(0xFF9E9E9E);
  static const Color tierSilverContainer = Color(0xFFF5F5F5);
  static const Color tierGold = Color(0xFFFFB300);
  static const Color tierGoldContainer = Color(0xFFFFF8E1);
  static const Color tierVip = Color(0xFF7C3AED);
  static const Color tierVipContainer = Color(0xFFF3E8FF);
}

/// Typography scale for ReserveHub.
class AppTextStyles {
  AppTextStyles._();

  static TextTheme get textTheme => GoogleFonts.plusJakartaSansTextTheme(
    const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
      headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
      labelLarge: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    ),
  );
}
