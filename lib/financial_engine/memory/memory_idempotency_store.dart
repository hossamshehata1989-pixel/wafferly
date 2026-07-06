import '../../financial_engine/results/operation_result.dart';
import '../../financial_engine/idempotency/idempotency_store.dart';

final class MemoryIdempotencyStore implements IdempotencyStore {
  final Map<String, OperationResult> _store = {};

  @override
  Future<OperationResult?> find(String key) async {
    return _store[key];
  }

  @override
  Future<void> save(String key, OperationResult result) async {
    _store[key] = result;
  }
}
