import 'package:flutter/material.dart';

/// Central Design System tokens and Theme configuration for DevPilot.
/// Faithfully translates the warm minimal aesthetic from Image 1 & Image 2.
class AppTheme {
  AppTheme._();

  // --- Palette & Surface Tokens ---
  /// Warm off-white / light cream base canvas (#FAF8F5).
  static const Color bgMain = Color(0xFFFAF8F5);

  /// Soft cream beige (#F6ECD9) used for detail headers and card accents.
  static const Color bgWarm = Color(0xFFF6ECD9);

  /// Warm tan/peach pastel (#FCEAD2) for primary project card.
  static const Color cardPeach = Color(0xFFFCEAD2);

  /// Soft sage/mint pastel (#D8EFE9) for secondary project card.
  static const Color cardMint = Color(0xFFD8EFE9);

  /// Soft lavender pastel (#E8E0F2) for auxiliary workflows.
  static const Color cardLavender = Color(0xFFE8E0F2);

  /// Deep charcoal/black (#161618) for schedule badges and contrast pills.
  static const Color darkPill = Color(0xFF161618);

  /// Pure white (#FFFFFF) for detail sheets and cards.
  static const Color surfaceCard = Color(0xFFFFFFFF);

  /// Dynamic accent orange (#E07A4C) for active progress and running indicators.
  static const Color accentOrange = Color(0xFFE07A4C);

  /// Vibrant green (#34C759) for completed steps and healthy telemetry.
  static const Color statusGreen = Color(0xFF34C759);

  /// Amber / Gold (#FFB300) for security gates and pending warnings.
  static const Color statusAmber = Color(0xFFFFB300);

  /// Destructive red (#FF3B30) for emergency alerts and console errors.
  static const Color statusRed = Color(0xFFFF3B30);

  // --- Complementary Tokens ---
  static const Color textDark = Color(0xFF1A1A1E);
  static const Color textSecondary = Color(0xFF6B6B76);
  static const Color textLight = Color(0xFFF5F5F7);
  static const Color borderSubtle = Color(0x14000000);
  static const Color borderMedium = Color(0x28000000);
  static const Color terminalBg = Color(0xFF0E0E14);
  static const Color terminalText = Color(0xFFB9D8AC);

  // --- Curvature / Corner Radii ---
  static final BorderRadius cardRadius = BorderRadius.circular(28);
  static final BorderRadius sheetRadius = BorderRadius.circular(32);
  static final BorderRadius pillRadius = BorderRadius.circular(999);
  static final BorderRadius buttonRadius = BorderRadius.circular(20);
  static final BorderRadius chipRadius = BorderRadius.circular(16);

  // --- Shadows ---
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> softShadow = [
    BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> floatingShadow = [
    BoxShadow(color: Color(0x18000000), blurRadius: 24, offset: Offset(0, 8)),
  ];

  // --- Typography ---
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: textDark,
    letterSpacing: -0.5,
    height: 1.15,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: textDark,
    letterSpacing: -0.4,
    height: 1.2,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: textDark,
    letterSpacing: -0.2,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: textDark,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textDark,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );

  static const TextStyle pillLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.1,
  );

  static const TextStyle monospace = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    height: 1.45,
    color: terminalText,
  );

  // --- Material 3 ThemeData ---
  static ThemeData get themeData => lightTheme;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgMain,
      cardColor: surfaceCard,
      colorScheme: const ColorScheme.light(
        primary: darkPill,
        onPrimary: Colors.white,
        secondary: accentOrange,
        onSecondary: Colors.white,
        surface: surfaceCard,
        onSurface: textDark,
        error: statusRed,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgMain,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textDark),
        titleTextStyle: titleLarge,
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: cardRadius,
          side: const BorderSide(color: borderSubtle),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderSubtle,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
