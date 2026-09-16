import 'package:flutter/material.dart';

@immutable
class ManagePalette extends ThemeExtension<ManagePalette> {
  // ===== Financial Overview Card =====
  final Color overviewIconBox;
  final Color overviewBorder;
  final Color overviewTotalCommitments;
  final Color overviewTotalBalance;
  final Color overviewAvailableToSpend;
  final Color overviewUpcomingDue;

  // ===== System Cards (2-column row) =====
  final Color debts;
  final Color recurring;

  // ===== Wide System Cards =====
  final Color goals;
  final Color budgets;
  final Color reservedMoney;

  // ===== Priority Boxes =====
  final Color priorityCritical;
  final Color priorityWarning;
  final Color priorityPositive;

  // ===== Scheduled Action Kind colors =====
  final Color actionExpense;
  final Color actionIncome;
  final Color actionGoalContribution;
  final Color actionTransfer;
  final Color actionInvestment;
  final Color actionBudgetReset;

  // ===== Panel surface =====
  final Color panelSurface;
  final Color panelShadow;

  const ManagePalette({
    required this.overviewIconBox,
    required this.overviewBorder,
    required this.overviewTotalCommitments,
    required this.overviewTotalBalance,
    required this.overviewAvailableToSpend,
    required this.overviewUpcomingDue,
    required this.debts,
    required this.recurring,
    required this.goals,
    required this.budgets,
    required this.reservedMoney,
    required this.priorityCritical,
    required this.priorityWarning,
    required this.priorityPositive,
    required this.actionExpense,
    required this.actionIncome,
    required this.actionGoalContribution,
    required this.actionTransfer,
    required this.actionInvestment,
    required this.actionBudgetReset,
    required this.panelSurface,
    required this.panelShadow,
  });

  static const ManagePalette dark = ManagePalette(
    overviewIconBox: Color(0xFF9C4DFF),
    overviewBorder: Color(0xFF4A2E8C),
    overviewTotalCommitments: Color(0xFF8392AD),
    overviewTotalBalance: Color(0xFF9AA7BB),
    overviewAvailableToSpend: Color(0xFF19D89B),
    overviewUpcomingDue: Color(0xFFFF5265),

    debts: Color(0xFFFF405A),
    recurring: Color(0xFF2585FF),

    goals: Color(0xFF19D89B),
    budgets: Color(0xFF9C4DFF),
    reservedMoney: Color(0xFFFFAA1F),

    priorityCritical: Color(0xFFFF405A),
    priorityWarning: Color(0xFFFFB11A),
    priorityPositive: Color(0xFF19D89B),

    actionExpense: Color(0xFFFF5265),
    actionIncome: Color(0xFF19D89B),
    actionGoalContribution: Color(0xFF3A7BFF),
    actionTransfer: Color(0xFFFF2D8D),
    actionInvestment: Color(0xFFFFB21A),
    actionBudgetReset: Color(0xFF9C4DFF),

    panelSurface: Color(0xFF06121F),
    panelShadow: Color(0x66000000),
  );

  static const ManagePalette light = ManagePalette(
    overviewIconBox: Color(0xFF7E57C2),
    overviewBorder: Color(0xFFB39DDB),
    overviewTotalCommitments: Color(0xFF546E7A),
    overviewTotalBalance: Color(0xFF607D8B),
    overviewAvailableToSpend: Color(0xFF00897B),
    overviewUpcomingDue: Color(0xFFD32F2F),

    debts: Color(0xFFD32F2F),
    recurring: Color(0xFF1976D2),

    goals: Color(0xFF00897B),
    budgets: Color(0xFF7E57C2),
    reservedMoney: Color(0xFFF57C00),

    priorityCritical: Color(0xFFD32F2F),
    priorityWarning: Color(0xFFF57C00),
    priorityPositive: Color(0xFF00897B),

    actionExpense: Color(0xFFD32F2F),
    actionIncome: Color(0xFF00897B),
    actionGoalContribution: Color(0xFF1976D2),
    actionTransfer: Color(0xFFC2185B),
    actionInvestment: Color(0xFFF57C00),
    actionBudgetReset: Color(0xFF7E57C2),

    panelSurface: Color(0xFFFFFFFF),
    panelShadow: Color(0x1A000000),
  );

  @override
  ManagePalette copyWith({
    Color? overviewIconBox,
    Color? overviewBorder,
    Color? overviewTotalCommitments,
    Color? overviewTotalBalance,
    Color? overviewAvailableToSpend,
    Color? overviewUpcomingDue,
    Color? debts,
    Color? recurring,
    Color? goals,
    Color? budgets,
    Color? reservedMoney,
    Color? priorityCritical,
    Color? priorityWarning,
    Color? priorityPositive,
    Color? actionExpense,
    Color? actionIncome,
    Color? actionGoalContribution,
    Color? actionTransfer,
    Color? actionInvestment,
    Color? actionBudgetReset,
    Color? panelSurface,
    Color? panelShadow,
  }) {
    return ManagePalette(
      overviewIconBox: overviewIconBox ?? this.overviewIconBox,
      overviewBorder: overviewBorder ?? this.overviewBorder,
      overviewTotalCommitments:
          overviewTotalCommitments ?? this.overviewTotalCommitments,
      overviewTotalBalance:
          overviewTotalBalance ?? this.overviewTotalBalance,
      overviewAvailableToSpend:
          overviewAvailableToSpend ?? this.overviewAvailableToSpend,
      overviewUpcomingDue:
          overviewUpcomingDue ?? this.overviewUpcomingDue,
      debts: debts ?? this.debts,
      recurring: recurring ?? this.recurring,
      goals: goals ?? this.goals,
      budgets: budgets ?? this.budgets,
      reservedMoney: reservedMoney ?? this.reservedMoney,
      priorityCritical: priorityCritical ?? this.priorityCritical,
      priorityWarning: priorityWarning ?? this.priorityWarning,
      priorityPositive: priorityPositive ?? this.priorityPositive,
      actionExpense: actionExpense ?? this.actionExpense,
      actionIncome: actionIncome ?? this.actionIncome,
      actionGoalContribution:
          actionGoalContribution ?? this.actionGoalContribution,
      actionTransfer: actionTransfer ?? this.actionTransfer,
      actionInvestment: actionInvestment ?? this.actionInvestment,
      actionBudgetReset: actionBudgetReset ?? this.actionBudgetReset,
      panelSurface: panelSurface ?? this.panelSurface,
      panelShadow: panelShadow ?? this.panelShadow,
    );
  }

  @override
  ManagePalette lerp(ThemeExtension<ManagePalette>? other, double t) {
    if (other is! ManagePalette) return this;
    return ManagePalette(
      overviewIconBox:
          Color.lerp(overviewIconBox, other.overviewIconBox, t)!,
      overviewBorder: Color.lerp(overviewBorder, other.overviewBorder, t)!,
      overviewTotalCommitments: Color.lerp(
          overviewTotalCommitments, other.overviewTotalCommitments, t)!,
      overviewTotalBalance:
          Color.lerp(overviewTotalBalance, other.overviewTotalBalance, t)!,
      overviewAvailableToSpend: Color.lerp(
          overviewAvailableToSpend, other.overviewAvailableToSpend, t)!,
      overviewUpcomingDue:
          Color.lerp(overviewUpcomingDue, other.overviewUpcomingDue, t)!,
      debts: Color.lerp(debts, other.debts, t)!,
      recurring: Color.lerp(recurring, other.recurring, t)!,
      goals: Color.lerp(goals, other.goals, t)!,
      budgets: Color.lerp(budgets, other.budgets, t)!,
      reservedMoney: Color.lerp(reservedMoney, other.reservedMoney, t)!,
      priorityCritical:
          Color.lerp(priorityCritical, other.priorityCritical, t)!,
      priorityWarning:
          Color.lerp(priorityWarning, other.priorityWarning, t)!,
      priorityPositive:
          Color.lerp(priorityPositive, other.priorityPositive, t)!,
      actionExpense: Color.lerp(actionExpense, other.actionExpense, t)!,
      actionIncome: Color.lerp(actionIncome, other.actionIncome, t)!,
      actionGoalContribution: Color.lerp(
          actionGoalContribution, other.actionGoalContribution, t)!,
      actionTransfer:
          Color.lerp(actionTransfer, other.actionTransfer, t)!,
      actionInvestment:
          Color.lerp(actionInvestment, other.actionInvestment, t)!,
      actionBudgetReset:
          Color.lerp(actionBudgetReset, other.actionBudgetReset, t)!,
      panelSurface: Color.lerp(panelSurface, other.panelSurface, t)!,
      panelShadow: Color.lerp(panelShadow, other.panelShadow, t)!,
    );
  }
}

extension ManagePaletteX on BuildContext {
  ManagePalette get managePalette =>
      Theme.of(this).extension<ManagePalette>() ?? ManagePalette.dark;
}