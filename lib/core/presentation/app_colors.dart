import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bgPage,
    required this.cardBg,
    required this.divider,
    required this.rowDivider,
    required this.chipBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDisabled,
    required this.primaryGreen, // Mantenemos el nombre por compatibilidad, pero con el tono Gold
    required this.gold,
    required this.teal,
    required this.tealLight,
    required this.amber,
    required this.green,
    required this.indigo,
    required this.purple,
    required this.red,
    required this.orange,
    required this.emergencyBg,
    required this.searchFill,
    required this.cardShadow,
    required this.railBg,
    required this.railSelectedBg,
    required this.railText,
    required this.railTextSelected,
    required this.railDivider,
  });

  final Color bgPage;
  final Color cardBg;
  final Color divider;
  final Color rowDivider;
  final Color chipBg;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textDisabled;
  final Color primaryGreen; // Mapeado a Oro Cálido
  final Color gold;
  final Color teal;
  final Color tealLight;
  final Color amber;
  final Color green;
  final Color indigo;
  final Color purple;
  final Color red;
  final Color orange;
  final Color emergencyBg;
  final Color searchFill;
  final BoxShadow cardShadow;
  final Color railBg;
  final Color railSelectedBg;
  final Color railText;
  final Color railTextSelected;
  final Color railDivider;

  // -------------------------------------------------------------
  // ☀️ MODO CLARO (Elegante, Blanco Perla & Acentos Oro / Navy)
  // -------------------------------------------------------------
  static const light = AppColors(
    bgPage: Color(0xFFF8FAFC),
    cardBg: Color(0xFFFFFFFF),
    divider: Color(0xFFE2E8F0),
    rowDivider: Color(0xFFF1F5F9),
    chipBg: Color(0xFFF1F5F9),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF334155),
    textMuted: Color(0xFF64748B),
    textDisabled: Color(0xFF94A3B8),
    primaryGreen: Color(0xFFC5A059), // 🌟 Dorado Bronce Elegante
    gold: Color(0xFFD4AF37),
    teal: Color(0xFF0D9488),
    tealLight: Color(0xFF14B8A6),
    amber: Color(0xFFD97706),
    green: Color(0xFF10B981),
    indigo: Color(0xFF6366F1),
    purple: Color(0xFF8B5CF6),
    red: Color(0xFFEF4444),
    orange: Color(0xFFF97316),
    emergencyBg: Color(0xFFFEE2E2),
    searchFill: Color(0xFFF1F5F9),
    cardShadow: BoxShadow(
      color: Color(0x0AC5A059),
      blurRadius: 20,
      offset: Offset(0, 4),
    ),
    railBg: Color(0xFFFFFFFF),
    railSelectedBg: Color(0xFFC5A059), // Dorado en el item activo
    railText: Color(0xFF64748B),
    railTextSelected: Color(0xFFFFFFFF),
    railDivider: Color(0xFFE2E8F0),
  );

  // -------------------------------------------------------------
  // 🌙 MODO OSCURO (Lujo Nocturno, Carbón / Obsidiana & Oro Champagne)
  // -------------------------------------------------------------
  static const dark = AppColors(
    bgPage: Color(0xFF0B0F17), // Carbón Noche Profundo
    cardBg: Color(0xFF161B26), // Pizarra Oscuro Mate
    divider: Color(0xFF232B3B),
    rowDivider: Color(0xFF1C2230),
    chipBg: Color(0xFF212836),
    searchFill: Color(0xFF1C2230),
    textPrimary: Color(0xFFF8FAFC), // Blanco Perla
    textSecondary: Color(0xFFCBD5E1),
    textMuted: Color(0xFF8A99AD),
    textDisabled: Color(0xFF475569),
    primaryGreen: Color(
      0xFFD4AF37,
    ), // 🌟 Oro Champagne Balanceado (sin deslumbrar)
    gold: Color(0xFFE5C158),
    teal: Color(0xFF14B8A6),
    tealLight: Color(0xFF2DD4BF),
    amber: Color(0xFFF59E0B),
    green: Color(0xFF10B981),
    indigo: Color(0xFF818CF8),
    purple: Color(0xFFA78BFA),
    red: Color(0xFFF87171),
    orange: Color(0xFFFB923C),
    emergencyBg: Color(0xFF3B1919),
    cardShadow: BoxShadow(
      color: Color(0x40000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
    railBg: Color(0xFF070A10),
    railSelectedBg: Color(0xFFD4AF37), // Oro en la barra lateral
    railText: Color(0xFF8A99AD),
    railTextSelected: Color(
      0xFF0F172A,
    ), // Texto oscuro sobre botón dorado para contraste perfecto
    railDivider: Color(0xFF232B3B),
  );

  @override
  AppColors copyWith({
    Color? bgPage,
    Color? cardBg,
    Color? divider,
    Color? rowDivider,
    Color? chipBg,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textDisabled,
    Color? primaryGreen,
    Color? gold,
    Color? teal,
    Color? tealLight,
    Color? amber,
    Color? green,
    Color? indigo,
    Color? purple,
    Color? red,
    Color? orange,
    Color? emergencyBg,
    Color? searchFill,
    BoxShadow? cardShadow,
    Color? railBg,
    Color? railSelectedBg,
    Color? railText,
    Color? railTextSelected,
    Color? railDivider,
  }) {
    return AppColors(
      bgPage: bgPage ?? this.bgPage,
      cardBg: cardBg ?? this.cardBg,
      divider: divider ?? this.divider,
      rowDivider: rowDivider ?? this.rowDivider,
      chipBg: chipBg ?? this.chipBg,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textDisabled: textDisabled ?? this.textDisabled,
      primaryGreen: primaryGreen ?? this.primaryGreen,
      gold: gold ?? this.gold,
      teal: teal ?? this.teal,
      tealLight: tealLight ?? this.tealLight,
      amber: amber ?? this.amber,
      green: green ?? this.green,
      indigo: indigo ?? this.indigo,
      purple: purple ?? this.purple,
      red: red ?? this.red,
      orange: orange ?? this.orange,
      emergencyBg: emergencyBg ?? this.emergencyBg,
      searchFill: searchFill ?? this.searchFill,
      cardShadow: cardShadow ?? this.cardShadow,
      railBg: railBg ?? this.railBg,
      railSelectedBg: railSelectedBg ?? this.railSelectedBg,
      railText: railText ?? this.railText,
      railTextSelected: railTextSelected ?? this.railTextSelected,
      railDivider: railDivider ?? this.railDivider,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bgPage: Color.lerp(bgPage, other.bgPage, t)!,
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      rowDivider: Color.lerp(rowDivider, other.rowDivider, t)!,
      chipBg: Color.lerp(chipBg, other.chipBg, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      primaryGreen: Color.lerp(primaryGreen, other.primaryGreen, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      teal: Color.lerp(teal, other.teal, t)!,
      tealLight: Color.lerp(tealLight, other.tealLight, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      green: Color.lerp(green, other.green, t)!,
      indigo: Color.lerp(indigo, other.indigo, t)!,
      purple: Color.lerp(purple, other.purple, t)!,
      red: Color.lerp(red, other.red, t)!,
      orange: Color.lerp(orange, other.orange, t)!,
      emergencyBg: Color.lerp(emergencyBg, other.emergencyBg, t)!,
      searchFill: Color.lerp(searchFill, other.searchFill, t)!,
      cardShadow: BoxShadow.lerp(cardShadow, other.cardShadow, t)!,
      railBg: Color.lerp(railBg, other.railBg, t)!,
      railSelectedBg: Color.lerp(railSelectedBg, other.railSelectedBg, t)!,
      railText: Color.lerp(railText, other.railText, t)!,
      railTextSelected: Color.lerp(
        railTextSelected,
        other.railTextSelected,
        t,
      )!,
      railDivider: Color.lerp(railDivider, other.railDivider, t)!,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
