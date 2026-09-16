import 'package:flutter/material.dart';

@immutable
class DebtPalette extends ThemeExtension<DebtPalette> {
  // =========================
  // Summary
  // =========================
  final Color summaryGradientStart;
  final Color summaryGradientEnd;
  final Color summaryBorder;
  final Color summaryGlow;
  final Color summaryDivider;

  // =========================
  // Category identity colors
  // =========================
  final Color loans;
  final Color creditCards;
  final Color installments;
  final Color borrowed;
  final Color temporary;
  final Color rotating;

  // =========================
  // Risk colors
  // =========================
  final Color upcoming;
  final Color dueSoon;
  final Color critical;
  final Color overdue;
  final Color inactive;

  // =========================
  // Card surface (base)
  // =========================
  final Color cardSurface;

  // =========================
  // Manage action
  // =========================
  final Color manageButtonText;

  // =========================
  // Progress
  // =========================
  final Color progressGradientStart;
  final Color progressGradientEnd;
  final Color progressBorder;
  final Color progressAccent;

  const DebtPalette({
    required this.summaryGradientStart,
    required this.summaryGradientEnd,
    required this.summaryBorder,
    required this.summaryGlow,
    required this.summaryDivider,
    required this.loans,
    required this.creditCards,
    required this.installments,
    required this.borrowed,
    required this.temporary,
    required this.rotating,
    required this.upcoming,
    required this.dueSoon,
    required this.critical,
    required this.overdue,
    required this.inactive,
    required this.cardSurface,
    required this.manageButtonText,
    required this.progressGradientStart,
    required this.progressGradientEnd,
    required this.progressBorder,
    required this.progressAccent,
  });

  // =========================
  // Dark theme
  // =========================
  static const DebtPalette dark = DebtPalette(
    summaryGradientStart: Color(0xFF082441),
    summaryGradientEnd: Color(0xFF061629),
    summaryBorder: Color(0xFF007BBD),
    summaryGlow: Color(0xFF008CFF),
    summaryDivider: Color(0xFF25435E),

    loans: Color(0xFF00C9FF),
    creditCards: Color(0xFFFF2D6F),
    installments: Color(0xFFFFB000),
    borrowed: Color(0xFF00E3A8),
    temporary: Color(0xFF9B6BFF),
    rotating: Color(0xFF00B9FF),

    upcoming: Color(0xFF00B9FF),
    dueSoon: Color(0xFFFF8A00),
    critical: Color(0xFFFF2D4F),
    overdue: Color(0xFFFF2D5F),
    inactive: Color(0xFF8EA8D6),

    cardSurface: Color(0xFF0A1626),

    manageButtonText: Color(0xFFFFFFFF),

    progressGradientStart: Color(0xFF101A72),
    progressGradientEnd: Color(0xFF27106B),
    progressBorder: Color(0xFF6B25FF),
    progressAccent: Color(0xFFC05CFF),
  );

  // =========================
  // Light theme
  // =========================
  static const DebtPalette light = DebtPalette(
    summaryGradientStart: Color(0xFFE3F2FD),
    summaryGradientEnd: Color(0xFFBBDEFB),
    summaryBorder: Color(0xFF1976D2),
    summaryGlow: Color(0xFF2196F3),
    summaryDivider: Color(0xFFB0BEC5),

    loans: Color(0xFF0288D1),
    creditCards: Color(0xFFD81B60),
    installments: Color(0xFFF57C00),
    borrowed: Color(0xFF00897B),
    temporary: Color(0xFF7E57C2),
    rotating: Color(0xFF0288D1),

    upcoming: Color(0xFF0288D1),
    dueSoon: Color(0xFFF57C00),
    critical: Color(0xFFE64A19),
    overdue: Color(0xFFD32F2F),
    inactive: Color(0xFF90A4AE),

    cardSurface: Color(0xFFFFFFFF),

    manageButtonText: Color(0xFFFFFFFF),

    progressGradientStart: Color(0xFF5E35B1),
    progressGradientEnd: Color(0xFF3949AB),
    progressBorder: Color(0xFF7E57C2),
    progressAccent: Color(0xFF7E57C2),
  );

  @override
  DebtPalette copyWith({
    Color? summaryGradientStart,
    Color? summaryGradientEnd,
    Color? summaryBorder,
    Color? summaryGlow,
    Color? summaryDivider,
    Color? loans,
    Color? creditCards,
    Color? installments,
    Color? borrowed,
    Color? temporary,
    Color? rotating,
    Color? upcoming,
    Color? dueSoon,
    Color? critical,
    Color? overdue,
    Color? inactive,
    Color? cardSurface,
    Color? manageButtonText,
    Color? progressGradientStart,
    Color? progressGradientEnd,
    Color? progressBorder,
    Color? progressAccent,
  }) {
    return DebtPalette(
      summaryGradientStart:
          summaryGradientStart ?? this.summaryGradientStart,
      summaryGradientEnd: summaryGradientEnd ?? this.summaryGradientEnd,
      summaryBorder: summaryBorder ?? this.summaryBorder,
      summaryGlow: summaryGlow ?? this.summaryGlow,
      summaryDivider: summaryDivider ?? this.summaryDivider,
      loans: loans ?? this.loans,
      creditCards: creditCards ?? this.creditCards,
      installments: installments ?? this.installments,
      borrowed: borrowed ?? this.borrowed,
      temporary: temporary ?? this.temporary,
      rotating: rotating ?? this.rotating,
      upcoming: upcoming ?? this.upcoming,
      dueSoon: dueSoon ?? this.dueSoon,
      critical: critical ?? this.critical,
      overdue: overdue ?? this.overdue,
      inactive: inactive ?? this.inactive,
      cardSurface: cardSurface ?? this.cardSurface,
      manageButtonText: manageButtonText ?? this.manageButtonText,
      progressGradientStart:
          progressGradientStart ?? this.progressGradientStart,
      progressGradientEnd: progressGradientEnd ?? this.progressGradientEnd,
      progressBorder: progressBorder ?? this.progressBorder,
      progressAccent: progressAccent ?? this.progressAccent,
    );
  }

  @override
  DebtPalette lerp(ThemeExtension<DebtPalette>? other, double t) {
    if (other is! DebtPalette) return this;
    return DebtPalette(
      summaryGradientStart:
          Color.lerp(summaryGradientStart, other.summaryGradientStart, t)!,
      summaryGradientEnd:
          Color.lerp(summaryGradientEnd, other.summaryGradientEnd, t)!,
      summaryBorder: Color.lerp(summaryBorder, other.summaryBorder, t)!,
      summaryGlow: Color.lerp(summaryGlow, other.summaryGlow, t)!,
      summaryDivider: Color.lerp(summaryDivider, other.summaryDivider, t)!,
      loans: Color.lerp(loans, other.loans, t)!,
      creditCards: Color.lerp(creditCards, other.creditCards, t)!,
      installments: Color.lerp(installments, other.installments, t)!,
      borrowed: Color.lerp(borrowed, other.borrowed, t)!,
      temporary: Color.lerp(temporary, other.temporary, t)!,
      rotating: Color.lerp(rotating, other.rotating, t)!,
      upcoming: Color.lerp(upcoming, other.upcoming, t)!,
      dueSoon: Color.lerp(dueSoon, other.dueSoon, t)!,
      critical: Color.lerp(critical, other.critical, t)!,
      overdue: Color.lerp(overdue, other.overdue, t)!,
      inactive: Color.lerp(inactive, other.inactive, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      manageButtonText:
          Color.lerp(manageButtonText, other.manageButtonText, t)!,
      progressGradientStart: Color.lerp(
          progressGradientStart, other.progressGradientStart, t)!,
      progressGradientEnd:
          Color.lerp(progressGradientEnd, other.progressGradientEnd, t)!,
      progressBorder: Color.lerp(progressBorder, other.progressBorder, t)!,
      progressAccent: Color.lerp(progressAccent, other.progressAccent, t)!,
    );
  }
}

extension DebtPaletteX on BuildContext {
  DebtPalette get debtPalette =>
      Theme.of(this).extension<DebtPalette>() ?? DebtPalette.dark;
}