import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design System Tokens for Monochrome Editorial Mobile.
/// Dark canvas (#121212), hairline rules (#2E2E2E), zero radius,
/// Montserrat typography for headings & numerals, and tracked uppercase labels.
abstract class T {
  // Canvas & Surfaces
  static const background     = Color(0xFF121212); // global scaffold
  static const surface        = Color(0xFF121212); // surface canvas
  static const surfaceMuted   = Color(0xFF1E1E1E); // progress tracks, subtle panels
  static const surfaceAlt     = Color(0xFF242424); // inputs, secondary surfaces

  // Foreground
  static const onSurface      = Color(0xFFFAFAFA); // headings, primary text, active icons
  static const onSurfaceVar   = Color(0xFF8E8E8E); // secondary text, inactive labels
  static const onSurfaceMuted = Color(0xFF525252); // tertiary, disabled
  static const primary        = Color(0xFFFAFAFA);
  static const onPrimary      = Color(0xFF121212);

  // Separator
  static const border         = Color(0xFF2E2E2E); // 1px hairlines — the ONLY separator

  // Semantic (inline deltas only — never use as fill or chrome)
  static const success        = Color(0xFF22C55E); // positive trend dot / running badge
  static const destructive    = Color(0xFF7F1D1D); // negative trend / delete
  static const amber          = Color(0xFFFFB300); // warning
  static const ember          = Color(0xFFFF5A1F); // ACTION log lines

  // Chart grayscale ramp
  static const chart1 = Color(0xFFFAFAFA);
  static const chart2 = Color(0xFFA3A3A3);
  static const chart3 = Color(0xFF737373);
  static const chart4 = Color(0xFF525252);
  static const chart5 = Color(0xFF2E2E2E);

  // ── SHAPES ── ZERO EVERYWHERE except badgeCircle and bottom nav top rounding
  static const zero         = BorderRadius.zero;
  static const badgeCircle  = BorderRadius.all(Radius.circular(9999));

  // ── SPACING ──
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 16;
  static const double lg  = 24;
  static const double xl  = 32;
  static const double x2l = 48;
  static const double x3l = 64;

  // ── TYPOGRAPHY ──
  // Montserrat: ALL headings and numerals — weight 400, negative tracking
  static TextStyle montserrat(
    double size, {
    FontWeight w = FontWeight.w400,
    double trackEm = 0,
    Color? color,
    double height = 1.1,
  }) =>
      GoogleFonts.montserrat(
        fontSize: size,
        fontWeight: w,
        letterSpacing: trackEm * size,
        color: color ?? onSurface,
        height: height,
      );

  // Geist / Neutral Sans: ALL labels, body, uppercase kickers
  static TextStyle geist(
    double size, {
    FontWeight w = FontWeight.w400,
    double trackEm = 0,
    Color? color,
    double height = 1.55,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: w,
        letterSpacing: trackEm * size,
        color: color ?? onSurface,
        height: height,
      );

  static TextStyle get displayLg    => montserrat(48, trackEm: -0.04);
  static TextStyle get displayMd    => montserrat(36, trackEm: -0.03);
  static TextStyle get displaySm    => montserrat(30, trackEm: -0.02);
  static TextStyle get numeralXl    => montserrat(60, trackEm: -0.03);
  static TextStyle get headlineLg   => montserrat(24, trackEm: -0.02);
  static TextStyle get headlineMd   => montserrat(20, trackEm: -0.01);
  static TextStyle get headlineSm   => montserrat(18, trackEm: -0.01);
  static TextStyle get bodyMd       => geist(14);
  static TextStyle get bodySm       => geist(12, color: onSurfaceVar);
  static TextStyle get labelUpMd    => geist(11, w: FontWeight.w600, trackEm: 0.2, color: onSurfaceVar);
  static TextStyle get labelUpSm    => geist(10, w: FontWeight.w500, trackEm: 0.2, color: onSurfaceVar);
  static TextStyle get labelUpXs    => geist(9,  w: FontWeight.w700, trackEm: 0.2, color: onSurfaceVar);
  static TextStyle get eyebrowWide  => geist(10, w: FontWeight.w500, trackEm: 0.4, color: onSurfaceVar);

  // Material ThemeData (Dark, Monochrome, Editorial)
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    cardColor: background,
    colorScheme: const ColorScheme.dark(
      primary: onSurface,
      onPrimary: background,
      secondary: success,
      surface: background,
      onSurface: onSurface,
      error: destructive,
    ),
    dividerTheme: const DividerThemeData(color: Colors.transparent, thickness: 0),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: onSurface),
    ),
    cardTheme: const CardThemeData(
      color: background,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
  );
}

/// Backward compatibility class for widgets referencing AppTheme.*
class AppTheme {
  AppTheme._();

  static const Color surface = T.background;
  static const Color surfaceAlt = T.surfaceMuted;
  static const Color surfaceRaised = T.surfaceAlt;
  static const Color surfaceInverse = T.background;

  static const Color primary = T.onSurface;
  static const Color primaryDeep = T.onSurface;
  static const Color onPrimary = T.background;
  static const Color accent = T.ember;

  static const Color onSurface = T.onSurface;
  static const Color onSurfaceVariant = T.onSurfaceVar;
  static const Color onInverse = T.onSurface;

  static const Color border = T.border;
  static const Color borderStrong = T.border;
  static const Color neutralSoft = T.surfaceMuted;

  // Backward Compatibility Aliases
  static const Color bgMain = T.background;
  static const Color surfaceCard = T.background;
  static const Color darkPill = T.surfaceMuted;
  static const Color textDark = T.onSurface;
  static const Color textPrimary = T.onSurface;
  static const Color primaryDark = T.onSurface;
  static const Color textSecondary = T.onSurfaceVar;
  static const Color textLight = T.onSurface;
  static const Color borderSubtle = T.border;
  static const Color borderMedium = T.border;
  static const Color accentOrange = T.ember;
  static const Color statusGreen = T.success;
  static const Color bgWarm = T.surfaceMuted;
  static const Color cardPeach = Color(0xFF1E1E1E);
  static const Color cardMint = Color(0xFF222222);
  static const Color cardLavender = Color(0xFF1A1A1A);
  static const Color statusAmber = T.amber;
  static const Color statusRed = T.destructive;
  static const Color terminalBg = Color(0xFF0A0A0A);
  static const Color terminalText = T.onSurface;

  // Shapes & Corner Radii — ZERO everywhere except badgeCircle
  static const BorderRadius cardRadius = BorderRadius.zero;
  static const BorderRadius thumbRadius = BorderRadius.zero;
  static const BorderRadius pillRadius = BorderRadius.zero;
  static const BorderRadius sheetRadius = BorderRadius.zero;
  static const BorderRadius buttonRadius = BorderRadius.zero;
  static const BorderRadius chipRadius = BorderRadius.zero;

  // Flat Surfaces (Zero Drop Shadows)
  static const List<BoxShadow> cardShadow = [];
  static const List<BoxShadow> softShadow = [];
  static const List<BoxShadow> floatingShadow = [];

  // Typography mapped to Montserrat and Geist
  static TextStyle get displayXl => T.montserrat(60, trackEm: -0.04).copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      );
  static TextStyle get displayMd => T.displayMd.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      );
  static TextStyle get numeralMd => T.montserrat(26, trackEm: -0.03).copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      );
  static TextStyle get numeralSm => T.montserrat(22, trackEm: -0.02).copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      );
  static TextStyle get headlineMd => T.headlineMd;
  static TextStyle get headlineSm => T.headlineSm;
  static TextStyle get cardTitle => T.headlineSm;

  static TextStyle get bodyMd => T.bodyMd;
  static TextStyle get bodySm => T.bodySm;
  static TextStyle get labelMd => T.labelUpMd;
  static TextStyle get labelSm => T.labelUpSm;
  static TextStyle get labelUppercase => T.labelUpXs;
  static TextStyle get caption => T.labelUpXs;

  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w400,
    color: T.onSurface,
    letterSpacing: -0.5,
    height: 1.15,
  );
  static const TextStyle displayMedium = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w400,
    color: T.onSurface,
    letterSpacing: -0.4,
    height: 1.2,
  );
  static const TextStyle titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: T.onSurface,
    letterSpacing: -0.2,
  );
  static const TextStyle titleMedium = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    color: T.onSurface,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: T.onSurface,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: T.onSurfaceVar,
  );
  static const TextStyle pillLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: T.background,
    letterSpacing: 1.0,
  );
  static const TextStyle monospace = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: T.onSurface,
  );

  static ThemeData get themeData => T.theme;
  static ThemeData get lightTheme => T.theme;
}
