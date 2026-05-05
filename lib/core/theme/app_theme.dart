import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Palette ──────────────────────────────────────────────────────────────
  static const Color primaryTeal = Color(0xFF00897B);
  static const Color primaryTealDark = Color(0xFF00695C);
  static const Color primaryTealLight = Color(0xFF4DB6AC);
  static const Color primaryTealPale = Color(0xFFE0F2F1);
  static const Color accentCyan = Color(0xFF26C6DA);
  static const Color accentPurple = Color(0xFF7C3AED);

  static const Color successColor = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warningColor = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color dangerColor = Color(0xFFDC2626);
  static const Color dangerLight = Color(0xFFFEE2E2);

  static const Color surfaceLight = Color(0xFFF0F9F8);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0F2922);
  static const Color textSecondary = Color(0xFF5C7A76);
  static const Color borderColor = Color(0xFFE2EAE9);

  // Dark theme palette
  static const Color surfaceDark = Color(0xFF0F2922);
  static const Color cardSurfaceDark = Color(0xFF1A3832);
  static const Color textPrimaryDark = Color(0xFFE0F2F1);
  static const Color textSecondaryDark = Color(0xFF9CAFAB);
  static const Color borderColorDark = Color(0xFF2D4A44);

  // ── Theme-aware colors (use in build(context) for light/dark support) ─────
  static Color surfaceColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? surfaceDark : surfaceLight;
  static Color cardColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? cardSurfaceDark : cardSurface;
  static Color textPrimaryColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textPrimaryDark : textPrimary;
  static Color textSecondaryColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textSecondaryDark : textSecondary;
  static Color borderColorFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? borderColorDark : borderColor;
  static Color primaryPaleColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? borderColorDark : primaryTealPale;
  static Color dangerLightColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? dangerColor.withValues(alpha: 0.2)
          : dangerLight;
  static Color warningLightColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? warningColor.withValues(alpha: 0.2)
          : warningLight;
  static Color successLightColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? successColor.withValues(alpha: 0.2)
          : successLight;

  static Color riskLightColorFor(BuildContext context, String level) {
    switch (level.toLowerCase()) {
      case 'low':
      case 'منخفض':
        return successLightColor(context);
      case 'medium':
      case 'متوسط':
        return warningLightColor(context);
      case 'high':
      case 'عالي':
        return dangerLightColor(context);
      default:
        return primaryPaleColor(context);
    }
  }

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryTeal, primaryTealDark],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF00BFA5), Color(0xFF00695C)],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00BFA5), Color(0xFF004D40)],
    stops: [0.0, 1.0],
  );

  static LinearGradient riskGradient(String level) {
    switch (level.toLowerCase()) {
      case 'low':
      case 'منخفض':
        return const LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF15803D)]);
      case 'medium':
      case 'متوسط':
        return const LinearGradient(colors: [Color(0xFFD97706), Color(0xFFB45309)]);
      case 'high':
      case 'عالي':
        return const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFB91C1C)]);
      default:
        return primaryGradient;
    }
  }

  // ── Shadows ───────────────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: primaryTeal.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get heroShadow => [
        BoxShadow(
          color: primaryTeal.withValues(alpha: 0.4),
          blurRadius: 32,
          offset: const Offset(0, 12),
          spreadRadius: -4,
        ),
      ];

  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: primaryTeal.withValues(alpha: 0.35),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  // ── Risk color ────────────────────────────────────────────────────────────
  static Color riskColor(String level) {
    switch (level.toLowerCase()) {
      case 'low':
      case 'منخفض':
        return successColor;
      case 'medium':
      case 'متوسط':
        return warningColor;
      case 'high':
      case 'عالي':
        return dangerColor;
      default:
        return primaryTeal;
    }
  }

  static Color riskLightColor(String level) {
    switch (level.toLowerCase()) {
      case 'low':
      case 'منخفض':
        return successLight;
      case 'medium':
      case 'متوسط':
        return warningLight;
      case 'high':
      case 'عالي':
        return dangerLight;
      default:
        return primaryTealPale;
    }
  }

  // ── Theme ─────────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    // IBM Plex Sans Arabic — modern geometric Arabic typeface
    final baseTextTheme = GoogleFonts.ibmPlexSansArabicTextTheme(
      const TextTheme(
        displayLarge: TextStyle(
          fontSize: 48, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -1.5,
        ),
        displayMedium: TextStyle(
          fontSize: 36, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -1,
        ),
        headlineLarge: TextStyle(
          fontSize: 28, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.3,
        ),
        headlineSmall: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600, color: textSecondary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w400, color: textPrimary, height: 1.6,
        ),
        bodyMedium: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w400, color: textPrimary, height: 1.6,
        ),
        bodySmall: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w400, color: textSecondary, height: 1.5,
        ),
        labelLarge: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary,
        ),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      textTheme: baseTextTheme,
      colorScheme: ColorScheme.light(
        primary: primaryTeal,
        onPrimary: Colors.white,
        primaryContainer: primaryTealPale,
        onPrimaryContainer: primaryTealDark,
        secondary: accentCyan,
        onSecondary: Colors.white,
        tertiary: accentPurple,
        surface: surfaceLight,
        onSurface: textPrimary,
        surfaceContainerHighest: cardSurface,
        outline: borderColor,
        error: dangerColor,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: surfaceLight,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: surfaceLight,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: GoogleFonts.ibmPlexSansArabic(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderColor, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FFFE),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryTeal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: dangerColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: dangerColor, width: 2),
        ),
        labelStyle: GoogleFonts.ibmPlexSansArabic(color: textSecondary, fontSize: 15),
        hintStyle: GoogleFonts.ibmPlexSansArabic(color: textSecondary.withValues(alpha: 0.6), fontSize: 14),
        prefixIconColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.focused) ? primaryTeal : textSecondary,
        ),
        floatingLabelStyle: GoogleFonts.ibmPlexSansArabic(color: primaryTeal, fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.ibmPlexSansArabic(fontSize: 16, fontWeight: FontWeight.w700),
          minimumSize: const Size(double.infinity, 54),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryTeal,
          side: const BorderSide(color: primaryTeal, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.ibmPlexSansArabic(fontSize: 16, fontWeight: FontWeight.w700),
          minimumSize: const Size(double.infinity, 54),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryTeal,
          textStyle: GoogleFonts.ibmPlexSansArabic(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryTeal,
        linearTrackColor: primaryTealPale,
        circularTrackColor: primaryTealPale,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaryTealPale,
        selectedColor: primaryTeal,
        labelStyle: const TextStyle(color: primaryTealDark, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 0,
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.ibmPlexSansArabicTextTheme(
      const TextTheme(
        displayLarge: TextStyle(
          fontSize: 48, fontWeight: FontWeight.w800, color: textPrimaryDark, letterSpacing: -1.5,
        ),
        displayMedium: TextStyle(
          fontSize: 36, fontWeight: FontWeight.w700, color: textPrimaryDark, letterSpacing: -1,
        ),
        headlineLarge: TextStyle(
          fontSize: 28, fontWeight: FontWeight.w700, color: textPrimaryDark, letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 24, fontWeight: FontWeight.w700, color: textPrimaryDark, letterSpacing: -0.3,
        ),
        headlineSmall: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w600, color: textPrimaryDark,
        ),
        titleLarge: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w700, color: textPrimaryDark,
        ),
        titleMedium: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600, color: textPrimaryDark,
        ),
        titleSmall: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600, color: textSecondaryDark,
        ),
        bodyLarge: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w400, color: textPrimaryDark, height: 1.6,
        ),
        bodyMedium: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w400, color: textPrimaryDark, height: 1.6,
        ),
        bodySmall: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w400, color: textSecondaryDark, height: 1.5,
        ),
        labelLarge: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600, color: textPrimaryDark,
        ),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      textTheme: baseTextTheme,
      colorScheme: ColorScheme.dark(
        primary: primaryTealLight,
        onPrimary: surfaceDark,
        primaryContainer: primaryTealDark,
        onPrimaryContainer: textPrimaryDark,
        secondary: accentCyan,
        onSecondary: surfaceDark,
        tertiary: accentPurple,
        surface: surfaceDark,
        onSurface: textPrimaryDark,
        surfaceContainerHighest: cardSurfaceDark,
        outline: borderColorDark,
        error: dangerColor,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: surfaceDark,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: surfaceDark,
        foregroundColor: textPrimaryDark,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: GoogleFonts.ibmPlexSansArabic(
          color: textPrimaryDark,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: textPrimaryDark),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardSurfaceDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderColorDark, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardSurfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderColorDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderColorDark, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryTealLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: dangerColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: dangerColor, width: 2),
        ),
        labelStyle: GoogleFonts.ibmPlexSansArabic(color: textSecondaryDark, fontSize: 15),
        hintStyle: GoogleFonts.ibmPlexSansArabic(color: textSecondaryDark.withValues(alpha: 0.7), fontSize: 14),
        prefixIconColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.focused) ? primaryTealLight : textSecondaryDark,
        ),
        floatingLabelStyle: GoogleFonts.ibmPlexSansArabic(color: primaryTealLight, fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTealLight,
          foregroundColor: surfaceDark,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryTealLight,
          foregroundColor: surfaceDark,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.ibmPlexSansArabic(fontSize: 16, fontWeight: FontWeight.w700),
          minimumSize: const Size(double.infinity, 54),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryTealLight,
          side: const BorderSide(color: primaryTealLight, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.ibmPlexSansArabic(fontSize: 16, fontWeight: FontWeight.w700),
          minimumSize: const Size(double.infinity, 54),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryTealLight,
          textStyle: GoogleFonts.ibmPlexSansArabic(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryTealLight,
        linearTrackColor: borderColorDark,
        circularTrackColor: borderColorDark,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: borderColorDark,
        selectedColor: primaryTealLight,
        labelStyle: const TextStyle(color: textPrimaryDark, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      dividerTheme: const DividerThemeData(
        color: borderColorDark,
        thickness: 1,
        space: 0,
      ),
    );
  }
}
