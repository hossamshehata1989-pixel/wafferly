import '../models/expense_resolution_analysis.dart';
import '../models/expense_resolution_option.dart';

class ExpenseResolutionAnalyzer {
  ExpenseResolutionAnalysis analyze({
    required double expenseAmount,
    required double selectedAccountBalance,
    required double totalLiquidity,
    required double totalSavings,
    required double totalReserved,

    required List<ExpenseResolutionOption> liquidityOptions,
    required List<ExpenseResolutionOption> savingsOptions,
    required List<ExpenseResolutionOption> reservedOptions,
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

      liquidityOptions: liquidityOptions,

      savingsOptions: savingsOptions,

      reservedOptions: reservedOptions,
    );
  }
}
