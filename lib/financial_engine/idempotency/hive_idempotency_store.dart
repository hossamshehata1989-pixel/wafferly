import 'package:hive/hive.dart';

import '../results/operation_result.dart';
import '../execution/financial_execution_summary.dart';
import 'idempotency_store.dart';

/// Durable idempotency store backed by Hive.
///
/// Only successful financial executions are persisted. A stored success is
/// reconstructed on a later engine instance so the same operation identity
/// can be safely retried after an app/process restart without creating a
/// second financial effect.
final class HiveIdempotencyStore implements IdempotencyStore {
  final Box<Map> box;

  const HiveIdempotencyStore(this.box);

  @override
  Future<OperationResult?> find(String key) async {
    final raw = box.get(key);
    if (raw == null) return null;

    final data = Map<String, dynamic>.from(raw);
    final resultType = data['resultType'];

    if (resultType != 'operationSucceeded') {
      throw StateError(
        'Unsupported durable idempotency result for key: $key',
      );
    }

    final summaryRaw = Map<String, dynamic>.from(
      data['summary'] as Map,
    );

    final createdTransactionIds = List<String>.from(
      (summaryRaw['createdTransactionIds'] as List?) ?? const <String>[],
    );

    final balanceChangesRaw = Map<String, dynamic>.from(
      (summaryRaw['balanceChanges'] as Map?) ?? const <String, dynamic>{},
    );

    final balanceChanges = <String, double>{};
    for (final entry in balanceChangesRaw.entries) {
      balanceChanges[entry.key] = (entry.value as num).toDouble();
    }

    final createdMutationIds = List<String>.from(
      (summaryRaw['createdMutationIds'] as List?) ?? const <String>[],
    );

    return OperationSucceeded(
      summary: FinancialExecutionSummary(
        createdTransactionIds: createdTransactionIds,
        balanceChanges: balanceChanges,
        createdMutationIds: createdMutationIds,
      ),
    );
  }

  @override
  Future<void> save(String key, OperationResult result) async {
    if (result is! OperationSucceeded) {
      throw StateError(
        'Only OperationSucceeded may be persisted in the durable '
        'idempotency store.',
      );
    }

    final summary = result.summary;

    await box.put(
      key,
      <String, dynamic>{
        'version': 1,
        'resultType': 'operationSucceeded',
        'summary': <String, dynamic>{
          'createdTransactionIds': summary.createdTransactionIds,
          'balanceChanges': summary.balanceChanges,
          'createdMutationIds': summary.createdMutationIds,
        },
      },
    );
  }
}
