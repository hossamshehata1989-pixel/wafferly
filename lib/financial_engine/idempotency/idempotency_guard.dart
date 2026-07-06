import '../execution_context/execution_context.dart';
import '../results/operation_result.dart';
import 'idempotency_store.dart';

final class IdempotencyGuard {
  final IdempotencyStore store;

  const IdempotencyGuard({required this.store});

  Future<OperationResult?> check(ExecutionContext context) {
    return store.find(context.idempotencyKey);
  }

  Future<void> remember(ExecutionContext context, OperationResult result) {
    return store.save(context.idempotencyKey, result);
  }
}
