/// Describes a financial event without affecting Financial Truth.
///
/// This object contains user-facing information that enriches the
/// persisted Transaction but must never change balances,
/// journal entries, or domain decisions.
///
/// ADR-0011:
/// - Shared across all Financial Commands.
/// - Must never contain operation-specific fields.
final class TransactionMetadata {
  /// When the financial event occurred.
  final DateTime occurredAt;

  /// Optional user note.
  final String? note;

  /// Payment method selected by the user.
  final String paymentMethod;

  /// Currency in which the transaction was entered.
  final String currencyCode;

  const TransactionMetadata({
    required this.occurredAt,
    this.note,
    required this.paymentMethod,
    required this.currencyCode,
  });
}
