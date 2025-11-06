import 'package:flutter/material.dart';

/// App color scheme matching the original React design
/// All colors are defined using HSL values converted to Flutter colors
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // Base colors from CSS variables
  static const Color background = Color(0xFFF9FAFB); // hsl(248 100% 98%)
  static const Color foreground = Color(0xFF2D3748); // hsl(230 25% 15%)

  // Card colors
  static const Color cardBackground = Color(0xFFFFFFFF); // hsl(0 0% 100%)
  static const Color cardForeground = Color(0xFF2D3748); // hsl(230 25% 15%)

  // Primary colors
  static const Color primary = Color(0xFF4A90E2); // hsl(220 70% 55%)
  static const Color primaryForeground = Color(0xFFFFFFFF); // hsl(0 0% 100%)

  // Secondary colors
  static const Color secondary = Color(0xFFE8D5E8); // hsl(315 25% 90%)
  static const Color secondaryForeground = Color(
    0xFF6B4C6B,
  ); // hsl(315 25% 25%)

  // Muted colors
  static const Color muted = Color(0xFFF5F5F6); // hsl(220 10% 96%)
  static const Color mutedForeground = Color(0xFF6B7280); // hsl(220 10% 45%)

  // Accent colors
  static const Color accent = Color(0xFFBF7FBF); // hsl(290 60% 70%)
  static const Color accentForeground = Color(0xFFFFFFFF); // hsl(0 0% 100%)

  // Destructive colors
  static const Color destructive = Color(0xFFEF4444); // hsl(0 84% 60%)
  static const Color destructiveForeground = Color(
    0xFFFFFFFF,
  ); // hsl(0 0% 100%)

  // Border and input colors
  static const Color border = Color(0xFFE0E7FF); // hsl(220 20% 90%)
  static const Color input = Color(0xFFF1F5F9); // hsl(220 20% 95%)
  static const Color ring = Color(0xFF4A90E2); // hsl(220 70% 55%)

  // Baby-specific colors
  static const Color babyPink = Color(0xFFE8C5E8); // hsl(325 50% 85%)
  static const Color babyBlue = Color(0xFFB3D9FF); // hsl(200 60% 80%)
  static const Color babyGreen = Color(0xFFC7E8C7); // hsl(150 40% 75%)
  static const Color babyPurple = Color(0xFFD1C4E9); // hsl(270 45% 80%)
  static const Color babyOrange = Color(0xFFFFDDB3); // hsl(30 70% 80%)
  static const Color babyYellow = Color(
    0xFFFFF9B3,
  ); // Light yellow for gradients

  // Shadow colors
  static const Color cardShadow = Color(0x1A4A90E2); // Primary with 10% opacity
  static const Color buttonShadow = Color(
    0x334A90E2,
  ); // Primary with 20% opacity
  static const Color softShadow = Color(0x4D4A90E2); // Primary with 30% opacity

  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accent],
  );

  static const LinearGradient softGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF8E8F8), // Light pink
      Color(0xFFE8F8FF), // Light blue
    ],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF), // White
      Color(0xFFF8FAFC), // Very light gray
    ],
  );

  // Baby-themed gradients
  static const LinearGradient babyPinkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8C5E8), Color(0xFFF0D0F0)],
  );

  static const LinearGradient babyBlueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB3D9FF), Color(0xFFCCE5FF)],
  );

  static const LinearGradient babyGreenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC7E8C7), Color(0xFFD4F0D4)],
  );

  static const LinearGradient babyPurpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD1C4E9), Color(0xFFE0D7F0)],
  );

  static const LinearGradient babyOrangeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFDDB3), Color(0xFFFFE6CC)],
  );

  // Page-specific background gradients
  static const LinearGradient homeBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x0FE8C5E8), // babyPink with 6% opacity
      background,
      Color(0x0FB3D9FF), // babyBlue with 6% opacity
    ],
  );

  static const LinearGradient sleepBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x33B3D9FF), // babyBlue with 20% opacity
      background,
      Color(0x33D1C4E9), // babyPurple with 20% opacity
    ],
  );

  static const LinearGradient feedingBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x33E8C5E8), // babyPink with 20% opacity
      background,
      Color(0x33FFDDb3), // babyOrange with 20% opacity
    ],
  );

  static const LinearGradient chartsBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x33D1C4E9), // babyPurple with 20% opacity
      background,
      Color(0x33B3D9FF), // babyBlue with 20% opacity
    ],
  );

  static const LinearGradient settingsBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x33C7E8C7), // babyGreen with 20% opacity
      background,
      Color(0x33D1C4E9), // babyPurple with 20% opacity
    ],
  );

  // Status colors
  static const Color success = babyGreen;
  static const Color warning = babyOrange;
  static const Color error = destructive;
  static const Color info = babyBlue;

  // ===== DARK THEME COLORS =====

  // Dark theme base colors
  static const Color darkBackground = Color(0xFF1D2428); // Primary background
  static const Color darkForeground = Color(0xFFFFFFFF); // Primary text

  // Dark theme card colors
  static const Color darkCardBackground = Color(
    0xFF14181B,
  ); // Secondary background
  static const Color darkCardForeground = Color(0xFFFFFFFF); // Primary text

  // Dark theme primary colors (keeping the same primary for brand consistency)
  static const Color darkPrimary = Color(0xFF5BA0F2); // Slightly brighter blue
  static const Color darkPrimaryForeground = Color(
    0xFFFFFFFF,
  ); // White text on primary

  // Dark theme secondary colors
  static const Color darkSecondary = Color(0xFF14181B); // Secondary background
  static const Color darkSecondaryForeground = Color(
    0xFF95A1AC,
  ); // Secondary text

  // Dark theme muted colors
  static const Color darkMuted = Color(0xFF14181B); // Secondary background
  static const Color darkMutedForeground = Color(0xFF95A1AC); // Secondary text

  // Dark theme accent colors
  static const Color darkAccent = Color(0xFF8B5A8B); // Darker purple accent
  static const Color darkAccentForeground = Color(0xFFFFFFFF); // Primary text

  // Dark theme border and input colors
  static const Color darkBorder = Color(0xFF2D3748); // Dark border
  static const Color darkInput = Color(0xFF14181B); // Secondary background
  static const Color darkRing = Color(0xFF5BA0F2); // Dark ring color

  // Dark theme baby-specific colors (darker versions)
  static const Color darkBabyPink = Color(0xFF4A2A4A); // Dark pink
  static const Color darkBabyBlue = Color(0xFF2A4A6B); // Dark blue
  static const Color darkBabyGreen = Color(0xFF2A4A2A); // Dark green
  static const Color darkBabyPurple = Color(0xFF3A2A4A); // Dark purple
  static const Color darkBabyOrange = Color(0xFF4A3A2A); // Dark orange
  static const Color darkBabyYellow = Color(0xFF4A4A2A); // Dark yellow

  // Dark theme gradients
  static const LinearGradient darkPrimaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkPrimary, darkAccent],
  );

  static const LinearGradient darkSoftGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2D1B2D), // Dark pink
      Color(0xFF1B2D3A), // Dark blue
    ],
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF14181B), // Secondary background
      Color(0xFF1D2428), // Primary background
    ],
  );

  // Dark theme page-specific background gradients - No gradient, just solid color
  static const LinearGradient darkHomeBackgroundGradient = LinearGradient(
    colors: [Color(0xFF1D2428), Color(0xFF1D2428)],
  );

  static const LinearGradient darkSleepBackgroundGradient = LinearGradient(
    colors: [Color(0xFF1D2428), Color(0xFF1D2428)],
  );

  static const LinearGradient darkFeedingBackgroundGradient = LinearGradient(
    colors: [Color(0xFF1D2428), Color(0xFF1D2428)],
  );

  static const LinearGradient darkChartsBackgroundGradient = LinearGradient(
    colors: [Color(0xFF1D2428), Color(0xFF1D2428)],
  );

  static const LinearGradient darkSettingsBackgroundGradient = LinearGradient(
    colors: [Color(0xFF1D2428), Color(0xFF1D2428)],
  );
}
