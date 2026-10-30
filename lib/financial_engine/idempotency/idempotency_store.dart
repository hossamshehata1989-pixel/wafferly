import 'idempotency_record.dart';

/// Persistence boundary for successful, fingerprint-verified idempotency
/// records. Implementations may read legacy v1 records for compatibility, but
/// new records must always include a non-empty request fingerprint.
abstract interface class IdempotencyStore {
  Future<IdempotencyRecord?> findRecord(String key);

  Future<void> saveRecord(IdempotencyRecord record);
}
