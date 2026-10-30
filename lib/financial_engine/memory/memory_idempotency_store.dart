import '../idempotency/idempotency_record.dart';
import '../idempotency/idempotency_store.dart';
import '../results/operation_result.dart';

final class MemoryIdempotencyStore implements IdempotencyStore {
  final Map<String, IdempotencyRecord> _store = {};

  @override
  Future<IdempotencyRecord?> findRecord(String key) async => _store[key];

  @override
  Future<void> saveRecord(IdempotencyRecord record) async {
    final fingerprint = record.requestFingerprint;
    if (fingerprint == null || fingerprint.trim().isEmpty) {
      throw StateError(
        'New in-memory idempotency records require a non-empty request '
        'fingerprint.',
      );
    }
    if (record.result is! OperationSucceeded) {
      throw StateError(
        'Only OperationSucceeded may be persisted in the in-memory '
        'idempotency store.',
      );
    }

    _store[record.key] = record;
  }
}
