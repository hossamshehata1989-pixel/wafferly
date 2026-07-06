import '../results/operation_result.dart';

abstract interface class IdempotencyStore {
  Future<OperationResult?> find(String key);

  Future<void> save(String key, OperationResult result);
}
