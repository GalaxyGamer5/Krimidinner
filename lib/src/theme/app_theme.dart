import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppPalette {
  static const Color noir = Color(0xFF0D0D0D);
  static const Color midnight = Color(0xFF152238);
  static const Color gold = Color(0xFFD4AF37);
  static const Color wine = Color(0xFF6B0F1A);
  static const Color parchment = Color(0xFFF5F5F5);
  static const Color mist = Color(0xFFB9C2D0);
  static const Color ash = Color(0xFF1D2330);
  static const Color ivory = Color(0xFFFFFAEF);
}

class AppTheme {
  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: AppPalette.gold,
      onPrimary: AppPalette.noir,
      secondary: AppPalette.wine,
      onSecondary: AppPalette.parchment,
      surface: AppPalette.noir,
      onSurface: AppPalette.parchment,
      error: Color(0xFFE76B74),
      onError: AppPalette.parchment,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppPalette.noir,
      brightness: Brightness.dark,
      textTheme: GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme),
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme, Brightness.dark),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppPalette.parchment,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: Colors.white.withOpacity(0.06),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppPalette.midnight.withOpacity(0.8),
        selectedColor: AppPalette.gold.withOpacity(0.18),
        secondarySelectedColor: AppPalette.gold.withOpacity(0.18),
        labelStyle: const TextStyle(color: AppPalette.parchment),
        side: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        labelStyle: const TextStyle(color: AppPalette.mist),
        hintStyle: TextStyle(color: AppPalette.mist.withOpacity(0.7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppPalette.gold),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        selectedIconTheme: const IconThemeData(color: AppPalette.gold),
        selectedLabelTextStyle: const TextStyle(
          color: AppPalette.gold,
          fontWeight: FontWeight.w700,
        ),
        unselectedIconTheme:
            IconThemeData(color: AppPalette.parchment.withOpacity(0.72)),
        unselectedLabelTextStyle:
            TextStyle(color: AppPalette.parchment.withOpacity(0.72)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppPalette.ash.withOpacity(0.95),
        indicatorColor: AppPalette.gold.withOpacity(0.16),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? AppPalette.gold
                : AppPalette.parchment.withOpacity(0.75),
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppPalette.gold,
          foregroundColor: AppPalette.noir,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.parchment,
          side: BorderSide(color: Colors.white.withOpacity(0.14)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      dividerTheme: DividerThemeData(color: Colors.white.withOpacity(0.08)),
    );
  }

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: AppPalette.midnight,
      onPrimary: AppPalette.parchment,
      secondary: AppPalette.gold,
      onSecondary: AppPalette.noir,
      surface: AppPalette.ivory,
      onSurface: AppPalette.midnight,
      error: Color(0xFFB3261E),
      onError: AppPalette.parchment,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppPalette.ivory,
      brightness: Brightness.light,
      textTheme: GoogleFonts.manropeTextTheme(ThemeData.light().textTheme),
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme, Brightness.light),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppPalette.midnight,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: Colors.white.withOpacity(0.76),
        surfaceTintColor: Colors.transparent,
        shadowColor: AppPalette.midnight.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: AppPalette.midnight.withOpacity(0.07)),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.white.withOpacity(0.9),
        selectedColor: AppPalette.gold.withOpacity(0.18),
        secondarySelectedColor: AppPalette.gold.withOpacity(0.18),
        labelStyle: const TextStyle(color: AppPalette.midnight),
        side: BorderSide(color: AppPalette.midnight.withOpacity(0.08)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.7),
        labelStyle: const TextStyle(color: AppPalette.midnight),
        hintStyle: TextStyle(color: AppPalette.midnight.withOpacity(0.56)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppPalette.midnight.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppPalette.midnight.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppPalette.gold),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppPalette.midnight,
          foregroundColor: AppPalette.parchment,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.midnight,
          side: BorderSide(color: AppPalette.midnight.withOpacity(0.12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      dividerTheme:
          DividerThemeData(color: AppPalette.midnight.withOpacity(0.08)),
    );
  }

  static TextTheme _textTheme(TextTheme textTheme, Brightness brightness) {
    final headlineColor = brightness == Brightness.dark
        ? AppPalette.parchment
        : AppPalette.midnight;
    final bodyColor = brightness == Brightness.dark
        ? AppPalette.parchment
        : AppPalette.midnight;

    return textTheme.copyWith(
      displayLarge: GoogleFonts.cinzel(
        textStyle: textTheme.displayLarge,
        fontWeight: FontWeight.w700,
        color: headlineColor,
        letterSpacing: 1.2,
      ),
      displayMedium: GoogleFonts.cinzel(
        textStyle: textTheme.displayMedium,
        fontWeight: FontWeight.w700,
        color: headlineColor,
      ),
      headlineLarge: GoogleFonts.cinzel(
        textStyle: textTheme.headlineLarge,
        fontWeight: FontWeight.w700,
        color: headlineColor,
      ),
      headlineMedium: GoogleFonts.cinzel(
        textStyle: textTheme.headlineMedium,
        fontWeight: FontWeight.w700,
        color: headlineColor,
      ),
      titleLarge: GoogleFonts.cinzel(
        textStyle: textTheme.titleLarge,
        fontWeight: FontWeight.w700,
        color: headlineColor,
      ),
      titleMedium: textTheme.titleMedium?.copyWith(
        color: bodyColor,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: textTheme.bodyLarge?.copyWith(
        color: bodyColor,
        height: 1.45,
      ),
      bodyMedium: textTheme.bodyMedium?.copyWith(
        color: bodyColor.withOpacity(0.88),
        height: 1.5,
      ),
      bodySmall: textTheme.bodySmall?.copyWith(
        color: bodyColor.withOpacity(0.68),
      ),
    );
  }
}

class MysteryDecor {
  static LinearGradient background(bool isDark) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? const [
              Color(0xFF060608),
              AppPalette.noir,
              Color(0xFF101725),
              Color(0xFF2A1017),
            ]
          : const [
              Color(0xFFFFFBF3),
              AppPalette.ivory,
              Color(0xFFF5EEE1),
              Color(0xFFE9DFCB),
            ],
    );
  }

  static BoxDecoration panel(BuildContext context, {double opacity = 0.9}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                Colors.white.withOpacity(opacity * 0.08),
                Colors.white.withOpacity(opacity * 0.03),
              ]
            : [
                Colors.white.withOpacity(0.86),
                Colors.white.withOpacity(0.72),
              ],
      ),
      border: Border.all(
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : AppPalette.midnight.withOpacity(0.08),
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withOpacity(0.26)
              : AppPalette.midnight.withOpacity(0.06),
          blurRadius: 30,
          offset: const Offset(0, 18),
        ),
      ],
    );
  }
}
