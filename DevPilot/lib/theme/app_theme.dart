import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central Design System tokens and Theme configuration for DevPilot.
/// Implements the high-contrast editorial "Paper & Lime Performance Mobile" aesthetic.
class AppTheme {
  AppTheme._();

  // --- Paper & Lime Core Palette ---

  /// Warm paper (#F4F2EC) — global scaffold and page canvas.
  static const Color surface = Color(0xFFF4F2EC);

  /// Paper-alt (#EBE8E0) — default card background, stat tiles, project preview cards.
  static const Color surfaceAlt = Color(0xFFEBE8E0);

  /// Pure white (#FFFFFF) — list-row cards to lift off paper without drop shadows.
  static const Color surfaceRaised = Color(0xFFFFFFFF);

  /// Ink (#0E0F0C) — dark feature cards (console, schedule tile, tactical deck).
  static const Color surfaceInverse = Color(0xFF0E0F0C);

  /// Electric lime (#D7FE47) — strictly rationed accent (active status pill, active chip).
  static const Color primary = Color(0xFFD7FE47);

  /// Pressed lime (#C8F02A) — interactive active tap states and success indicators.
  static const Color primaryDeep = Color(0xFFC8F02A);

  /// Ink on lime (#0E0F0C).
  static const Color onPrimary = Color(0xFF0E0F0C);

  /// Ember orange (#FF5A1F) — reserved strictly for hero numerals and alert notification dots.
  static const Color accent = Color(0xFFFF5A1F);

  /// Ink primary text (#0E0F0C).
  static const Color onSurface = Color(0xFF0E0F0C);

  /// Mute gray (#8A8A82) — metadata, kicker labels, inactive states.
  static const Color onSurfaceVariant = Color(0xFF8A8A82);

  /// Warm paper text on ink surfaces (#F4F2EC).
  static const Color onInverse = Color(0xFFF4F2EC);

  /// Hairline dividers (#E3E0D7) — 1px dividers, never card outlines.
  static const Color border = Color(0xFFE3E0D7);

  /// Progress track fills (#DDDAD1).
  static const Color borderStrong = Color(0xFFDDDAD1);

  /// De-emphasized data bar fill (#C8C5BA).
  static const Color neutralSoft = Color(0xFFC8C5BA);

  // --- Backward Compatibility Aliases ---
  static const Color bgMain = surface;
  static const Color surfaceCard = surfaceRaised;
  static const Color darkPill = surfaceInverse;
  static const Color textDark = onSurface;
  static const Color textSecondary = onSurfaceVariant;
  static const Color textLight = onInverse;
  static const Color borderSubtle = border;
  static const Color borderMedium = borderStrong;
  static const Color accentOrange = accent;
  static const Color statusGreen = primaryDeep;
  static const Color bgWarm = surfaceAlt;
  static const Color cardPeach = surfaceAlt;
  static const Color cardMint = surfaceAlt;
  static const Color cardLavender = surfaceAlt;
  static const Color statusAmber = Color(0xFFFFB300);
  static const Color statusRed = Color(0xFFFF3B30);
  static const Color terminalBg = surfaceInverse;
  static const Color terminalText = Color(0xFFB9D8AC);

  // --- Shapes & Corner Radii ---

  /// Default 24px corner radius for all cards, tiles, and grouped surfaces.
  static final BorderRadius cardRadius = BorderRadius.circular(24);

  /// 18px corner radius for photos and thumbnail previews.
  static final BorderRadius thumbRadius = BorderRadius.circular(18);

  /// Full 9999px pill radius for chips, buttons, avatars, and badges.
  static final BorderRadius pillRadius = BorderRadius.circular(9999);

  // Backward compatibility shape aliases
  static final BorderRadius sheetRadius = BorderRadius.circular(24);
  static final BorderRadius buttonRadius = pillRadius;
  static final BorderRadius chipRadius = pillRadius;

  // --- Flat Surfaces (Zero Drop Shadows) ---
  static const List<BoxShadow> cardShadow = [];
  static const List<BoxShadow> softShadow = [];
  static const List<BoxShadow> floatingShadow = [];

  // --- Typography (Space Grotesk & Inter) ---

  // Space Grotesk: Display Numerals & Headings with Tabular Figures
  static TextStyle get displayXl => GoogleFonts.spaceGrotesk(
        fontSize: 84,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.04 * 84,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: onSurface,
      );

  static TextStyle get displayMd => GoogleFonts.spaceGrotesk(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.04 * 34,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: onSurface,
      );

  static TextStyle get numeralMd => GoogleFonts.spaceGrotesk(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.04 * 26,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: onSurface,
      );

  static TextStyle get numeralSm => GoogleFonts.spaceGrotesk(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.04 * 22,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: onSurface,
      );

  static TextStyle get headlineMd => GoogleFonts.spaceGrotesk(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.01 * 17,
        color: onSurface,
      );

  static TextStyle get headlineSm => GoogleFonts.spaceGrotesk(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.01 * 15,
        color: onSurface,
      );

  static TextStyle get cardTitle => GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.01 * 16,
        color: onSurface,
      );

  // Inter: Humanist Neutral Sans for Body, Labels & Tracked-out Kickers
  static TextStyle get bodyMd => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: onSurface,
      );

  static TextStyle get bodySm => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: onSurfaceVariant,
      );

  static TextStyle get labelMd => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.12,
        color: onSurface,
      );

  static TextStyle get labelSm => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.11,
        color: onSurfaceVariant,
      );

  static TextStyle get labelUppercase => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.8,
        color: onSurfaceVariant,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 9,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.35,
        color: onSurfaceVariant,
      );

  // Backward compatibility legacy typography (const to preserve const widget trees)
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: onSurface,
    letterSpacing: -0.5,
    height: 1.15,
  );
  static const TextStyle displayMedium = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: onSurface,
    letterSpacing: -0.4,
    height: 1.2,
  );
  static const TextStyle titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: onSurface,
    letterSpacing: -0.2,
  );
  static const TextStyle titleMedium = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: onSurface,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: onSurface,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: onSurfaceVariant,
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
    color: Color(0xFFB9D8AC),
  );

  // --- Material 3 ThemeData ---
  static ThemeData get themeData => lightTheme;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: surface,
      cardColor: surfaceAlt,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: onPrimary,
        secondary: primaryDeep,
        onSecondary: onPrimary,
        surface: surface,
        onSurface: onSurface,
        surfaceContainerHighest: surfaceAlt,
        error: accent,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: onSurface),
        titleTextStyle: headlineMd,
      ),
      cardTheme: CardThemeData(
        color: surfaceAlt,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: cardRadius,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        thickness: 0,
        space: 0,
      ),
    );
  }
}
