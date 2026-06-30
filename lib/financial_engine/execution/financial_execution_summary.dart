class FinancialExecutionSummary {
  final List<String> createdTransactionIds;

  final Map<String, double> balanceChanges;

  final List<String> createdMutationIds;

  const FinancialExecutionSummary({
    required this.createdTransactionIds,
    required this.balanceChanges,
    required this.createdMutationIds,
  });
}
