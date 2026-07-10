final class IncomeIntent {
  final String destinationAccountId;

  final double amount;

  final String categoryId;

  const IncomeIntent({
    required this.destinationAccountId,
    required this.amount,
    required this.categoryId,
  });
}
