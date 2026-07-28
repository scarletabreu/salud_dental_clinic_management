import 'package:flutter/material.dart';
import 'app_colors.dart';

const _kSeedColor = Color(0xFFC5A059);

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _kSeedColor,
      brightness: Brightness.light,
      primary: const Color(0xFFC5A059),
      surface: const Color(0xFFFFFFFF),
    ).copyWith(surfaceContainerLowest: AppColors.light.bgPage),
    useMaterial3: true,
    extensions: const [AppColors.light],
  );

  static ThemeData get dark => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _kSeedColor,
      brightness: Brightness.dark,
      primary: const Color(0xFFD4AF37),
      surface: const Color(0xFF161B26),
    ).copyWith(surfaceContainerLowest: AppColors.dark.bgPage),
    useMaterial3: true,
    extensions: const [AppColors.dark],
  );
}
