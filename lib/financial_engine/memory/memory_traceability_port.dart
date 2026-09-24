import '../ports/traceability_port.dart';
import '../traceability/traceability_record.dart';

final class MemoryTraceabilityPort implements TraceabilityPort {
  final Map<String, TraceabilityRecord> records = {};

  @override
  Future<void> save(TraceabilityRecord record) async {
    records[record.traceId] = record;
  }

  @override
  Future<TraceabilityRecord?> findById(String traceId) async {
    return records[traceId];
  }

  @override
  Future<List<TraceabilityRecord>> findByIdempotencyKey(String key) async {
    return records.values
        .where((record) => record.idempotencyKey == key)
        .toList(growable: false);
  }

  @override
  Future<List<TraceabilityRecord>> findByTransactionId(
    String transactionId,
  ) async {
    return records.values
        .where((record) => record.transactionIds.contains(transactionId))
        .toList(growable: false);
  }
}
