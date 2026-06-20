class TransferToSavingResult {
  final String? sourceAccountId;

  final String savingAccountId;

  final double amount;

  const TransferToSavingResult({
    this.sourceAccountId,
    required this.savingAccountId,
    required this.amount,
  });
}
