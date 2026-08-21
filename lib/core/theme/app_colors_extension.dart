import 'package:flutter/material.dart';

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color questBlue;
  final Color midnightSlate;
  final Color surface;
  final Color background;
  final Color card;
  final Color border;
  final Color auroraPurple;
  final Color emerald;
  final Color amber;
  final Color crimson;
  final Color skyBlue;
  final Color gold;
  final Color textPrimary;
  final Color textPrimary87;
  final Color textPrimary70;
  final Color textPrimary54;
  final Color textPrimary38;
  final Color textPrimary24;
  final Color textPrimary12;
  final Color textSecondary;
  final Color textMuted;
  final Color background87;
  final Color background54;
  final Color background45;

  const AppColorsExtension({
    required this.questBlue,
    required this.midnightSlate,
    required this.surface,
    required this.background,
    required this.card,
    required this.border,
    required this.auroraPurple,
    required this.emerald,
    required this.amber,
    required this.crimson,
    required this.skyBlue,
    required this.gold,
    required this.textPrimary,
    required this.textPrimary87,
    required this.textPrimary70,
    required this.textPrimary54,
    required this.textPrimary38,
    required this.textPrimary24,
    required this.textPrimary12,
    required this.textSecondary,
    required this.textMuted,
    required this.background87,
    required this.background54,
    required this.background45,
  });

  @override
  ThemeExtension<AppColorsExtension> copyWith({
    Color? questBlue,
    Color? midnightSlate,
    Color? surface,
    Color? background,
    Color? card,
    Color? border,
    Color? auroraPurple,
    Color? emerald,
    Color? amber,
    Color? crimson,
    Color? skyBlue,
    Color? gold,
    Color? textPrimary,
    Color? textPrimary87,
    Color? textPrimary70,
    Color? textPrimary54,
    Color? textPrimary38,
    Color? textPrimary24,
    Color? textPrimary12,
    Color? textSecondary,
    Color? textMuted,
    Color? background87,
    Color? background54,
    Color? background45,
  }) {
    return AppColorsExtension(
      questBlue: questBlue ?? this.questBlue,
      midnightSlate: midnightSlate ?? this.midnightSlate,
      surface: surface ?? this.surface,
      background: background ?? this.background,
      card: card ?? this.card,
      border: border ?? this.border,
      auroraPurple: auroraPurple ?? this.auroraPurple,
      emerald: emerald ?? this.emerald,
      amber: amber ?? this.amber,
      crimson: crimson ?? this.crimson,
      skyBlue: skyBlue ?? this.skyBlue,
      gold: gold ?? this.gold,
      textPrimary: textPrimary ?? this.textPrimary,
      textPrimary87: textPrimary87 ?? this.textPrimary87,
      textPrimary70: textPrimary70 ?? this.textPrimary70,
      textPrimary54: textPrimary54 ?? this.textPrimary54,
      textPrimary38: textPrimary38 ?? this.textPrimary38,
      textPrimary24: textPrimary24 ?? this.textPrimary24,
      textPrimary12: textPrimary12 ?? this.textPrimary12,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      background87: background87 ?? this.background87,
      background54: background54 ?? this.background54,
      background45: background45 ?? this.background45,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> lerp(
    covariant ThemeExtension<AppColorsExtension>? other,
    double t,
  ) {
    if (other is! AppColorsExtension) {
      return this;
    }
    return AppColorsExtension(
      questBlue: Color.lerp(questBlue, other.questBlue, t)!,
      midnightSlate: Color.lerp(midnightSlate, other.midnightSlate, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      border: Color.lerp(border, other.border, t)!,
      auroraPurple: Color.lerp(auroraPurple, other.auroraPurple, t)!,
      emerald: Color.lerp(emerald, other.emerald, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      crimson: Color.lerp(crimson, other.crimson, t)!,
      skyBlue: Color.lerp(skyBlue, other.skyBlue, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textPrimary87: Color.lerp(textPrimary87, other.textPrimary87, t)!,
      textPrimary70: Color.lerp(textPrimary70, other.textPrimary70, t)!,
      textPrimary54: Color.lerp(textPrimary54, other.textPrimary54, t)!,
      textPrimary38: Color.lerp(textPrimary38, other.textPrimary38, t)!,
      textPrimary24: Color.lerp(textPrimary24, other.textPrimary24, t)!,
      textPrimary12: Color.lerp(textPrimary12, other.textPrimary12, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      background87: Color.lerp(background87, other.background87, t)!,
      background54: Color.lerp(background54, other.background54, t)!,
      background45: Color.lerp(background45, other.background45, t)!,
    );
  }
}

extension ThemeContextExtension on BuildContext {
  AppColorsExtension get colors => Theme.of(this).extension<AppColorsExtension>()!;
}
