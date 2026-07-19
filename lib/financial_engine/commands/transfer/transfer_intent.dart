/// Represents the financial intent behind a money transfer.
///
/// This object contains only domain data that affects financial
/// decisions, balance validation, journal generation,
/// and execution planning.
///
/// ADR-00xx:
/// - Financial Truth starts here.
/// - No UI concerns.
/// - No execution concerns.
/// - No persistence concerns.
final class TransferIntent {
  /// Account that will be debited.
  ///
  /// Money leaves this account.
  final String fromAccountId;

  /// Account that will be credited.
  ///
  /// Money is transferred into this account.
  final String toAccountId;

  /// Amount of money to transfer.
  ///
  /// Must be greater than zero.
  final double amount;

  const TransferIntent({
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
  });
}
