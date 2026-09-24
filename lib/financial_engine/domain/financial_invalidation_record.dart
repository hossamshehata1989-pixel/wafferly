import 'financial_transaction_record.dart';

/// Immutable financial write model describing the invalidation of previously
/// accepted financial truth.
///
/// The original transaction is preserved as [before]. The invalidation is a
/// separate financial write model that explains why the original truth is no
/// longer active and carries the ledger-neutralizing effect.
final class FinancialInvalidationRecord {
  final String invalidationId;
  final String originalTransactionId;
  final FinancialTransactionRecord before;

  const FinancialInvalidationRecord({
    required this.invalidationId,
    required this.originalTransactionId,
    required this.before,
  });
}
