import '../domain/financial_invalidation_record.dart';
import '../ports/invalidation_port.dart';

final class MemoryInvalidationPort implements InvalidationPort {
  final Map<String, FinancialInvalidationRecord> records = {};

  @override
  Future<void> save(FinancialInvalidationRecord record) async {
    records[record.invalidationId] = record;
  }

  @override
  Future<FinancialInvalidationRecord?> findById(String invalidationId) async {
    return records[invalidationId];
  }

  @override
  Future<FinancialInvalidationRecord?> findByOriginalTransactionId(
    String transactionId,
  ) async {
    for (final record in records.values) {
      if (record.originalTransactionId == transactionId) return record;
    }
    return null;
  }

  @override
  Future<void> delete(String invalidationId) async {
    records.remove(invalidationId);
  }
}
