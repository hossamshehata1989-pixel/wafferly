import '../results/operation_result.dart';

final class IdempotencyRecord {
  final String key;
  final OperationResult result;

  const IdempotencyRecord({required this.key, required this.result});
}
