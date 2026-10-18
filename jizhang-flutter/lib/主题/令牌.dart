import 'package:flutter/material.dart';

/// 设计令牌：来自 DESIGN.md，组件只消费这里的值。
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.divider,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.primary,
    required this.primaryHover,
    required this.primaryLight,
    required this.primarySoft,
    required this.income,
    required this.incomeBg,
    required this.expense,
    required this.expenseBg,
    required this.liability,
    required this.liabilityBg,
    required this.balance,
    required this.space1,
    required this.space2,
    required this.space3,
    required this.space4,
    required this.space5,
    required this.space6,
    required this.space8,
    required this.space10,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusXl,
    required this.radiusFull,
  });

  final Color bg;
  final Color surface;
  final Color surface2;
  final Color border;
  final Color divider;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color primary;
  final Color primaryHover;
  final Color primaryLight;
  final Color primarySoft;
  final Color income;
  final Color incomeBg;
  final Color expense;
  final Color expenseBg;
  final Color liability;
  final Color liabilityBg;
  final Color balance;

  final double space1;
  final double space2;
  final double space3;
  final double space4;
  final double space5;
  final double space6;
  final double space8;
  final double space10;

  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double radiusXl;
  final double radiusFull;

  static const light = AppTokens(
    bg: Color(0xFFFFFFFF),
    surface: Color(0xFFF7F8FA),
    surface2: Color(0xFFF1F3F7),
    border: Color(0xFFE5E8EF),
    divider: Color(0xFFF0F2F6),
    borderStrong: Color(0xFFD2D7E2),
    textPrimary: Color(0xFF1A1D29),
    textSecondary: Color(0xFF6B7280),
    textDisabled: Color(0xFFA6ADBB),
    primary: Color(0xFF4F46E5),
    primaryHover: Color(0xFF4338CA),
    primaryLight: Color(0xFFEEF2FF),
    primarySoft: Color(0xFFC7D2FE),
    income: Color(0xFF16A34A),
    incomeBg: Color(0xFFECFDF3),
    expense: Color(0xFFE5484D),
    expenseBg: Color(0xFFFEECEC),
    liability: Color(0xFFEA580C),
    liabilityBg: Color(0xFFFFF1E6),
    balance: Color(0xFF4F46E5),
    space1: 4,
    space2: 8,
    space3: 12,
    space4: 16,
    space5: 20,
    space6: 24,
    space8: 32,
    space10: 40,
    radiusSm: 6,
    radiusMd: 10,
    radiusLg: 16,
    radiusXl: 20,
    radiusFull: 999,
  );

  @override
  AppTokens copyWith({
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? border,
    Color? divider,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDisabled,
    Color? primary,
    Color? primaryHover,
    Color? primaryLight,
    Color? primarySoft,
    Color? income,
    Color? incomeBg,
    Color? expense,
    Color? expenseBg,
    Color? liability,
    Color? liabilityBg,
    Color? balance,
    double? space1,
    double? space2,
    double? space3,
    double? space4,
    double? space5,
    double? space6,
    double? space8,
    double? space10,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? radiusXl,
    double? radiusFull,
  }) {
    return AppTokens(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textDisabled: textDisabled ?? this.textDisabled,
      primary: primary ?? this.primary,
      primaryHover: primaryHover ?? this.primaryHover,
      primaryLight: primaryLight ?? this.primaryLight,
      primarySoft: primarySoft ?? this.primarySoft,
      income: income ?? this.income,
      incomeBg: incomeBg ?? this.incomeBg,
      expense: expense ?? this.expense,
      expenseBg: expenseBg ?? this.expenseBg,
      liability: liability ?? this.liability,
      liabilityBg: liabilityBg ?? this.liabilityBg,
      balance: balance ?? this.balance,
      space1: space1 ?? this.space1,
      space2: space2 ?? this.space2,
      space3: space3 ?? this.space3,
      space4: space4 ?? this.space4,
      space5: space5 ?? this.space5,
      space6: space6 ?? this.space6,
      space8: space8 ?? this.space8,
      space10: space10 ?? this.space10,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
      radiusXl: radiusXl ?? this.radiusXl,
      radiusFull: radiusFull ?? this.radiusFull,
    );
  }

  @override
  AppTokens lerp(covariant AppTokens? other, double t) {
    if (other == null) return this;
    return AppTokens(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryHover: Color.lerp(primaryHover, other.primaryHover, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      income: Color.lerp(income, other.income, t)!,
      incomeBg: Color.lerp(incomeBg, other.incomeBg, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      expenseBg: Color.lerp(expenseBg, other.expenseBg, t)!,
      liability: Color.lerp(liability, other.liability, t)!,
      liabilityBg: Color.lerp(liabilityBg, other.liabilityBg, t)!,
      balance: Color.lerp(balance, other.balance, t)!,
      space1: space1 + (other.space1 - space1) * t,
      space2: space2 + (other.space2 - space2) * t,
      space3: space3 + (other.space3 - space3) * t,
      space4: space4 + (other.space4 - space4) * t,
      space5: space5 + (other.space5 - space5) * t,
      space6: space6 + (other.space6 - space6) * t,
      space8: space8 + (other.space8 - space8) * t,
      space10: space10 + (other.space10 - space10) * t,
      radiusSm: radiusSm + (other.radiusSm - radiusSm) * t,
      radiusMd: radiusMd + (other.radiusMd - radiusMd) * t,
      radiusLg: radiusLg + (other.radiusLg - radiusLg) * t,
      radiusXl: radiusXl + (other.radiusXl - radiusXl) * t,
      radiusFull: radiusFull + (other.radiusFull - radiusFull) * t,
    );
  }
}

extension AppTokensX on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}
