import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design System Tokens for DevPilot Light & Modern Theme.
/// Features high-contrast crisp readability, soft light canvas (#F8FAFC),
/// pure white surfaces (#FFFFFF), curated vibrant accent colors,
/// rounded corners to break rigid contrast, and clean Montserrat/Inter typography.
abstract class T {
  // ── CANVAS & SURFACES (Light Mode Default) ──
  static const background     = Color(0xFFF8FAFC); // global scaffold canvas
  static const surface        = Color(0xFFFFFFFF); // clean white cards
  static const surfaceMuted   = Color(0xFFF1F5F9); // secondary containers / rails
  static const surfaceAlt     = Color(0xFFE2E8F0); // subtle borders / alt surfaces

  // ── FOREGROUND & TEXT ──
  static const onSurface      = Color(0xFF0F172A); // headings, primary high-contrast text
  static const onSurfaceVar   = Color(0xFF475569); // secondary text, comfortable labels
  static const onSurfaceMuted = Color(0xFF94A3B8); // tertiary text, subtle meta
  static const primary        = Color(0xFF0F172A); // primary button / core brand
  static const onPrimary      = Color(0xFFFFFFFF); // text on primary

  // ── BORDERS & SEPARATORS ──
  static const border         = Color(0xFFE2E8F0); // 1px clean hairline border
  static const borderStrong   = Color(0xFFCBD5E1); // enhanced separator

  // ── CURATED ACCENT COLORS ──
  static const accent         = Color(0xFF4F46E5); // Indigo
  static const accentBlue     = Color(0xFF2563EB); // Royal Blue
  static const accentTeal     = Color(0xFF0D9488); // Teal
  static const accentPurple   = Color(0xFF7C3AED); // Violet
  static const accentRose     = Color(0xFFE11D48); // Rose
  static const ember          = Color(0xFFEA580C); // Warm Orange

  // ── SEMANTIC STATUS ──
  static const success        = Color(0xFF16A34A); // Emerald green (running, success)
  static const destructive    = Color(0xFFDC2626); // Crimson red (errors, failed)
  static const amber          = Color(0xFFD97706); // Amber (warnings, pending)

  // ── CHART TONAL RAMP ──
  static const chart1 = Color(0xFF2563EB);
  static const chart2 = Color(0xFF4F46E5);
  static const chart3 = Color(0xFF0D9488);
  static const chart4 = Color(0xFF94A3B8);
  static const chart5 = Color(0xFFE2E8F0);

  // ── SHAPES & CORNER RADII (Breaks rigid contrast) ──
  static const zero         = BorderRadius.zero;
  static const rSm          = BorderRadius.all(Radius.circular(8));
  static const rMd          = BorderRadius.all(Radius.circular(12));
  static const rLg          = BorderRadius.all(Radius.circular(16));
  static const rFull        = BorderRadius.all(Radius.circular(9999));
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
  // Montserrat: Headings & Numerals — confident, clear, well-spaced
  static TextStyle montserrat(
    double size, {
    FontWeight w = FontWeight.w500,
    double trackEm = 0,
    Color? color,
    double height = 1.15,
  }) =>
      GoogleFonts.montserrat(
        fontSize: size,
        fontWeight: w,
        letterSpacing: trackEm * size,
        color: color ?? onSurface,
        height: height,
      );

  // Inter / Sans: Body text, UI labels, metadata — legible, non-congested
  static TextStyle geist(
    double size, {
    FontWeight w = FontWeight.w400,
    double trackEm = 0,
    Color? color,
    double height = 1.45,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: w,
        letterSpacing: trackEm * size,
        color: color ?? onSurface,
        height: height,
      );

  static TextStyle get displayLg    => montserrat(40, w: FontWeight.w600, trackEm: -0.02);
  static TextStyle get displayMd    => montserrat(32, w: FontWeight.w600, trackEm: -0.02);
  static TextStyle get displaySm    => montserrat(26, w: FontWeight.w600, trackEm: -0.01);
  static TextStyle get numeralXl    => montserrat(52, w: FontWeight.w600, trackEm: -0.02);
  static TextStyle get headlineLg   => montserrat(22, w: FontWeight.w600, trackEm: -0.01);
  static TextStyle get headlineMd   => montserrat(18, w: FontWeight.w600);
  static TextStyle get headlineSm   => montserrat(15, w: FontWeight.w600);
  static TextStyle get bodyMd       => geist(14, w: FontWeight.w400);
  static TextStyle get bodySm       => geist(12, color: onSurfaceVar);
  static TextStyle get labelUpMd    => geist(11, w: FontWeight.w600, trackEm: 0.05, color: onSurfaceVar);
  static TextStyle get labelUpSm    => geist(10, w: FontWeight.w600, trackEm: 0.05, color: onSurfaceVar);
  static TextStyle get labelUpXs    => geist(9,  w: FontWeight.w700, trackEm: 0.04, color: onSurfaceVar);
  static TextStyle get eyebrowWide  => geist(10, w: FontWeight.w600, trackEm: 0.08, color: onSurfaceVar);

  // Material ThemeData (Clean Light Theme Default)
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: background,
    cardColor: surface,
    colorScheme: const ColorScheme.light(
      primary: primary,
      onPrimary: onPrimary,
      secondary: accent,
      surface: surface,
      onSurface: onSurface,
      error: destructive,
    ),
    dividerTheme: const DividerThemeData(color: border, thickness: 1),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: onSurface),
    ),
    cardTheme: const CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: rMd,
        side: BorderSide(color: border, width: 1),
      ),
    ),
  );
}

/// Backward compatibility class for widgets referencing AppTheme.*
class AppTheme {
  AppTheme._();

  static const Color surface = T.surface;
  static const Color surfaceAlt = T.surfaceMuted;
  static const Color surfaceRaised = T.surface;
  static const Color surfaceInverse = T.onSurface;

  static const Color primary = T.primary;
  static const Color primaryDeep = T.onSurface;
  static const Color onPrimary = T.onPrimary;
  static const Color accent = T.accent;

  static const Color border = T.border;
  static const Color borderSubtle = T.border;
  static const Color borderStrong = T.borderStrong;
  static const Color borderMedium = T.borderStrong;
  static const Color neutralSoft = T.surfaceAlt;
  static const Color background = T.background;
  static const Color onSurface = T.onSurface;
  static const Color onSurfaceVariant = T.onSurfaceVar;
  static const Color onInverse = T.surface;
  static const Color textPrimary = T.onSurface;
  static const Color textSecondary = T.onSurfaceVar;
  static const Color textMuted = T.onSurfaceMuted;
  static const Color textDark = T.onSurface;
  static const Color textLight = T.surface;
  static const Color primaryDark = T.onSurface;

  static const Color bgMain = T.background;
  static const Color bgWarm = T.surfaceMuted;
  static const Color surfaceCard = T.surface;
  static const Color darkPill = T.onSurface;
  static const Color cardPeach = T.surfaceMuted;
  static const Color cardMint = T.surfaceMuted;
  static const Color cardLavender = T.surfaceMuted;
  static const Color accentOrange = T.ember;

  static const Color success = T.success;
  static const Color statusGreen = T.success;
  static const Color statusRed = T.destructive;
  static const Color statusAmber = T.amber;
  static const Color error = T.destructive;
  static const Color warning = T.amber;

  static const Color terminalBg = Color(0xFF0F172A);
  static const Color terminalText = Color(0xFFB9D8AC);

  static const BorderRadius cardRadius = T.rMd;
  static const BorderRadius thumbRadius = T.rSm;
  static const BorderRadius pillRadius = T.rFull;
  static const BorderRadius sheetRadius = T.rLg;
  static const BorderRadius buttonRadius = T.rSm;
  static const BorderRadius chipRadius = T.rFull;

  static const List<BoxShadow> cardShadow = [];
  static const List<BoxShadow> softShadow = [];
  static const List<BoxShadow> floatingShadow = [];

  static ThemeData get lightTheme => T.theme;
  static ThemeData get darkTheme => T.theme;
  static ThemeData get themeData => T.theme;

  static TextStyle get display => T.displayLg;
  static TextStyle get displayXl => T.numeralXl;
  static TextStyle get displayMd => T.displayMd;
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
  static TextStyle get titleLarge => T.displayMd;
  static TextStyle get titleMedium => T.headlineMd;
  static TextStyle get titleSmall => T.headlineSm;
  static TextStyle get headlineMd => T.headlineMd;
  static TextStyle get headlineSm => T.headlineSm;
  static TextStyle get cardTitle => T.headlineSm;
  static TextStyle get body => T.bodyMd;
  static TextStyle get bodyMd => T.bodyMd;
  static TextStyle get bodySm => T.bodySm;
  static TextStyle get labelMd => T.bodySm;
  static TextStyle get labelSm => T.labelUpSm;
  static TextStyle get labelUppercase => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.8,
        color: onSurfaceVariant,
      );
  static TextStyle get caption => T.labelUpSm;
  static TextStyle get mono => GoogleFonts.jetBrainsMono(fontSize: 12, color: T.onSurface);
  static TextStyle get monoSmall => GoogleFonts.jetBrainsMono(fontSize: 10, color: T.onSurfaceVar);

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: T.onSurfaceVar,
  );
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: T.onSurface,
    letterSpacing: -0.5,
    height: 1.15,
  );
  static const TextStyle displayMedium = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: T.onSurface,
    letterSpacing: -0.4,
    height: 1.2,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: T.onSurface,
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
}
