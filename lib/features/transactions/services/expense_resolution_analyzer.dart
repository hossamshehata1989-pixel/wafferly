import '../models/expense_resolution_analysis.dart';

class ExpenseResolutionAnalyzer {
  ExpenseResolutionAnalysis analyze({
    required double expenseAmount,
    required double selectedAccountBalance,
    required double totalLiquidity,
    required double totalSavings,
    required double totalReserved,
  }) {
    final shortage = expenseAmount - selectedAccountBalance;

    final otherLiquidityBalance = (totalLiquidity - selectedAccountBalance)
        .clamp(0.0, double.infinity);

    return ExpenseResolutionAnalysis(
      expenseAmount: expenseAmount,
      selectedAccountBalance: selectedAccountBalance,
      totalLiquidity: totalLiquidity,
      totalSavings: totalSavings,
      totalReserved: totalReserved,
      shortage: shortage,
      otherLiquidityBalance: otherLiquidityBalance,
    );
  }
}
