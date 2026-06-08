class ExpenseResolutionAnalysis {
  final double expenseAmount;

  final double selectedAccountBalance;

  final double totalLiquidity;

  final double totalSavings;

  final double totalReserved;

  final double shortage;

  final double otherLiquidityBalance;

  const ExpenseResolutionAnalysis({
    required this.expenseAmount,
    required this.selectedAccountBalance,
    required this.totalLiquidity,
    required this.totalSavings,
    required this.totalReserved,
    required this.shortage,
    required this.otherLiquidityBalance,
  });

  bool get hasOtherLiquidity => otherLiquidityBalance > 0;
  bool get hasSavings => totalSavings > 0;

  bool get hasReservedMoney => totalReserved > 0;
}
