import 'package:flutter/material.dart';

class AppColors {
  // Strava Signature Athletic Flame Orange
  static const Color primary = Color(0xFFFC4C02);
  static const Color primaryLight = Color(0xFFFF6D3B);
  static const Color primaryDark = Color(0xFFE03E00);
  static const Color primaryGradientStart = Color(0xFFFC4C02);
  static const Color primaryGradientEnd = Color(0xFFFF8533);

  // Athletic Secondary Accents
  static const Color secondary = Color(0xFF007AFF); // Track Electric Blue
  static const Color secondaryLight = Color(0xFF38BDF8);
  static const Color secondaryDark = Color(0xFF0056B3);

  // Performance Metrics
  static const Color accentGreen = Color(0xFF00E676); // Sprint Mint
  static const Color accentGreenLight = Color(0xFFD1FAE5);
  static const Color accentYellow = Color(0xFFFFD600); // Summit Gold
  static const Color accentYellowLight = Color(0xFFFEF3C7);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentPurpleLight = Color(0xFFEDE9FE);

  // Modern Light Theme (Clean Chalk Track & Pure White)
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);
  static const Color lightSurfaceTint = Color(0xFFE5E7EB);
  static const Color lightCardAccent = Color(0xFFFFF2EC);
  static const Color lightTextPrimary = Color(0xFF1F2937);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightTextTertiary = Color(0xFF9CA3AF);

  // Modern Dark Theme (Stealth Carbon & Matte Obsidian)
  static const Color darkBackground = Color(0xFF101216);
  static const Color darkSurface = Color(0xFF1B1F27);
  static const Color darkSurfaceElevated = Color(0xFF242A35);
  static const Color darkSurfaceTint = Color(0xFF2D3543);
  static const Color darkCardAccent = Color(0xFF2C1914);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkTextTertiary = Color(0xFF6B7280);

  // Status
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFD600);
  static const Color error = Color(0xFFFF3B30);
  static const Color info = Color(0xFF007AFF);

  // Backwards-Compatible Palette Aliases
  static const Color blue = secondary;
  static const Color purple = accentPurple;
  static const Color amber = warning;
  static const Color rose = error;
  static const Color darkInput = darkSurfaceElevated;
  static const Color darkBorder = darkSurfaceTint;
  static const Color darkTextMuted = darkTextTertiary;
  static const Color lightInput = lightSurfaceTint;
  static const Color lightBorder = lightSurfaceTint;
  static const Color lightTextMuted = lightTextTertiary;
}
