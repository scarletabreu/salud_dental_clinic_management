import 'package:flutter/material.dart';
import 'app_colors.dart';

const _kSeedColor = Color(0xFF3385FF);

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _kSeedColor,
      brightness: Brightness.light,
    ).copyWith(surfaceContainerLowest: const Color(0xFFEEF2F8)),
    useMaterial3: true,
    extensions: const [AppColors.light],
  );

  static ThemeData get dark => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _kSeedColor,
      brightness: Brightness.dark,
    ).copyWith(surfaceContainerLowest: const Color(0xFF0F1623)),
    useMaterial3: true,
    extensions: const [AppColors.dark],
  );
}
