import 'package:hive/hive.dart';

import '../execution/financial_execution_summary.dart';
import '../results/operation_result.dart';
import 'idempotency_record.dart';
import 'idempotency_store.dart';

/// Durable idempotency store backed by Hive.
///
/// Version 1 records predate request fingerprints. They are retained and can
/// still be read, but the fingerprint-aware guard refuses to replay them
/// because their original request cannot be verified. New writes always use
/// version 2 and require a non-empty request fingerprint.
final class HiveIdempotencyStore implements IdempotencyStore {
  final Box<Map> box;

  const HiveIdempotencyStore(this.box);

  @override
  Future<IdempotencyRecord?> findRecord(String key) async {
    final raw = box.get(key);
    if (raw == null) return null;

    final data = Map<String, dynamic>.from(raw);
    final version = (data['version'] as num?)?.toInt() ?? 1;
    if (version != 1 && version != 2) {
      throw StateError(
        'Unsupported durable idempotency record version: $version',
      );
    }

    String? fingerprint;
    if (version == 2) {
      final storedFingerprint = data['requestFingerprint'];
      if (storedFingerprint is! String || storedFingerprint.trim().isEmpty) {
        throw StateError(
          'Version 2 durable idempotency record has a missing or invalid '
          'request fingerprint for key: $key',
        );
      }
      fingerprint = storedFingerprint;
    }

    final result = _readSuccessfulResult(key, data);

    return IdempotencyRecord(
      key: key,
      requestFingerprint: fingerprint,
      result: result,
    );
  }

  @override
  Future<void> saveRecord(IdempotencyRecord record) async {
    final fingerprint = record.requestFingerprint;
    if (fingerprint == null || fingerprint.trim().isEmpty) {
      throw StateError(
        'New durable idempotency records require a non-empty request '
        'fingerprint.',
      );
    }

    if (record.result is! OperationSucceeded) {
      throw StateError(
        'Only OperationSucceeded may be persisted in the durable '
        'idempotency store.',
      );
    }

    final result = record.result as OperationSucceeded;
    final summary = result.summary;
    final data = <String, dynamic>{
      'version': 2,
      'resultType': 'operationSucceeded',
      'requestFingerprint': fingerprint,
      'summary': <String, dynamic>{
        'createdTransactionIds': summary.createdTransactionIds,
        'balanceChanges': summary.balanceChanges,
        'createdMutationIds': summary.createdMutationIds,
      },
    };

    await box.put(record.key, data);
  }

  OperationSucceeded _readSuccessfulResult(
    String key,
    Map<String, dynamic> data,
  ) {
    if (data['resultType'] != 'operationSucceeded') {
      throw StateError('Unsupported durable idempotency result for key: $key');
    }

    final summaryRaw = Map<String, dynamic>.from(data['summary'] as Map);
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
}
