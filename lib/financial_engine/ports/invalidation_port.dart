import '../domain/financial_invalidation_record.dart';

/// Persistence port for immutable financial invalidations.
abstract interface class InvalidationPort {
  Future<void> save(FinancialInvalidationRecord record);
  Future<FinancialInvalidationRecord?> findById(String invalidationId);
  Future<void> delete(String invalidationId);
  Future<FinancialInvalidationRecord?> findByOriginalTransactionId(
    String transactionId,
  );
}
