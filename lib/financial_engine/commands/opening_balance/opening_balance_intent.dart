/// Represents the financial genesis of an account inside the ledger.
///
/// The amount may be zero. A zero opening balance is still a financial
/// event because it establishes the account's first ledger checkpoint.
final class OpeningBalanceIntent {
  final String accountId;
  final double amount;
  final bool isLiability;

  const OpeningBalanceIntent({
    required this.accountId,
    required this.amount,
    required this.isLiability,
  });
}
