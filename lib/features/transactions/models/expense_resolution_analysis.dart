import 'expense_resolution_option.dart';

class ExpenseResolutionAnalysis {
  final double expenseAmount;

  final double selectedAccountBalance;

  final double totalLiquidity;

  final double totalSavings;

  final double totalReserved;

  final double shortage;

  final double otherLiquidityBalance;

  final List<ExpenseResolutionOption> liquidityOptions;

  final List<ExpenseResolutionOption> savingsOptions;

  final List<ExpenseResolutionOption> reservedOptions;

  const ExpenseResolutionAnalysis({
    required this.expenseAmount,
    required this.selectedAccountBalance,
    required this.totalLiquidity,
    required this.totalSavings,
    required this.totalReserved,
    required this.shortage,
    required this.otherLiquidityBalance,
    required this.liquidityOptions,
    required this.savingsOptions,
    required this.reservedOptions,
  });

  bool get hasOtherLiquidity => otherLiquidityBalance > 0;
  bool get hasSavings => totalSavings > 0;

  bool get hasReservedMoney => totalReserved > 0;
}
