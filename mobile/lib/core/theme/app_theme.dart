import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Palet warna brand ROTASI (DESIGN_SYSTEM.md).
abstract final class AppColors {
  static const Color primary = Color(0xFF0C4A6E);
  static const Color primaryLight = Color(0xFF0284C7);
  static const Color accent = Color(0xFF0D9488);

  static const Color sun = Color(0xFFF59E0B);
  static const Color sand = Color(0xFFFDF6EC);
  static const Color skyLight = Color(0xFFE0F2FE);
  static const Color neutralLight = Color(0xFFF1F5F9);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color border = Color(0xFFCBD5E1);
  static const Color white = Color(0xFFFFFFFF);

  /// Status tekanan darah ROTASI — 6 tier (revisi Beranda).
  /// Hipotensi <90/60 #EE65C1, Normal <120/<80 #79B038, Waspada 120-129/<80 #FFD66E,
  /// Berisiko 130-139/80-89 #F08E2B, Bahaya ≥140/≥90 #C85858, Darurat ≥160/110 #E23F25
  static const Color hypotension = Color(0xFFEE65C1);
  static const Color normal = Color(0xFF79B038);
  static const Color elevated = Color(0xFFFFD66E);
  static const Color stage1 = Color(0xFFF08E2B);
  static const Color crisis = Color(0xFFC85858);
  static const Color emergency = Color(0xFFE23F25);
}

abstract final class AppTheme {
  static ThemeData get light {
    const family = 'PlusJakartaSans';
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: family,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.white,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
        },
      ),
    );
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.neutralLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        centerTitle: true,
      ),
      textTheme: base.textTheme
          .apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
            fontFamily: family,
          )
          .copyWith(
            headlineLarge: base.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            headlineMedium: base.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            titleLarge: base.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            titleMedium: base.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: family,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: family,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: family,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: AppColors.white,
          backgroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: family,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.white,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
