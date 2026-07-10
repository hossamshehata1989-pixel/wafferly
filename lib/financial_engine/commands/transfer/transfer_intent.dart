final class TransferIntent {
  final String sourceAccountId;

  final String destinationAccountId;

  final double amount;

  const TransferIntent({
    required this.sourceAccountId,
    required this.destinationAccountId,
    required this.amount,
  });
}
