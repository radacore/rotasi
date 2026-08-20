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

  /// Status tekanan darah (AHA 2025).
  static const Color normal = Color(0xFF16A34A);
  static const Color elevated = Color(0xFFCA8A04);
  static const Color stage1 = Color(0xFFEA580C);
  static const Color crisis = Color(0xFFDC2626);
}

abstract final class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.white,
      ),
      scaffoldBackgroundColor: AppColors.neutralLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        centerTitle: true,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
