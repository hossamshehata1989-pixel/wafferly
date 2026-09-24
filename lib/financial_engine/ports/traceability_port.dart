import '../traceability/traceability_record.dart';

/// Persistence boundary for immutable Financial Operation history.
///
/// Traceability is audit/history state, not Financial Reality.
abstract interface class TraceabilityPort {
  Future<void> save(TraceabilityRecord record);
  Future<TraceabilityRecord?> findById(String traceId);
  Future<List<TraceabilityRecord>> findByIdempotencyKey(String key);
  Future<List<TraceabilityRecord>> findByTransactionId(String transactionId);
}
