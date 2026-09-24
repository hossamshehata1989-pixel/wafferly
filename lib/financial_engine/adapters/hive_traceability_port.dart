import 'package:hive/hive.dart';

import '../ports/traceability_port.dart';
import '../traceability/traceability_record.dart';

/// Durable Hive adapter for immutable operation history.
final class HiveTraceabilityPort implements TraceabilityPort {
  final Box<Map> box;

  const HiveTraceabilityPort(this.box);

  @override
  Future<void> save(TraceabilityRecord record) async {
    await box.put(record.traceId, <String, dynamic>{
      'version': 1,
      'traceId': record.traceId,
      'operationType': record.operationType,
      'operationId': record.operationId,
      'idempotencyKey': record.idempotencyKey,
      'status': record.status,
      'actorMemberId': record.actorMemberId,
      'source': record.source,
      'commitmentId': record.commitmentId,
      'scheduleRuleId': record.scheduleRuleId,
      'occurrenceId': record.occurrenceId,
      'transactionIds': record.transactionIds,
      'mutationIds': record.mutationIds,
      'error': record.error,
      'startedAt': record.startedAt.toIso8601String(),
      'completedAt': record.completedAt.toIso8601String(),
    });
  }

  @override
  Future<TraceabilityRecord?> findById(String traceId) async {
    final raw = box.get(traceId);
    if (raw == null) return null;
    return _fromMap(Map<String, dynamic>.from(raw));
  }

  @override
  Future<List<TraceabilityRecord>> findByIdempotencyKey(String key) async {
    return box.values
        .map((raw) => _fromMap(Map<String, dynamic>.from(raw)))
        .where((record) => record.idempotencyKey == key)
        .toList(growable: false);
  }

  @override
  Future<List<TraceabilityRecord>> findByTransactionId(
    String transactionId,
  ) async {
    return box.values
        .map((raw) => _fromMap(Map<String, dynamic>.from(raw)))
        .where((record) => record.transactionIds.contains(transactionId))
        .toList(growable: false);
  }

  TraceabilityRecord _fromMap(Map<String, dynamic> data) {
    return TraceabilityRecord(
      traceId: data['traceId'] as String,
      operationType: data['operationType'] as String,
      operationId: data['operationId'] as String?,
      idempotencyKey: data['idempotencyKey'] as String,
      status: data['status'] as String,
      actorMemberId: data['actorMemberId'] as String?,
      source: data['source'] as String?,
      commitmentId: data['commitmentId'] as String?,
      scheduleRuleId: data['scheduleRuleId'] as String?,
      occurrenceId: data['occurrenceId'] as String?,
      transactionIds: List<String>.from(
        (data['transactionIds'] as List?) ?? const <String>[],
      ),
      mutationIds: List<String>.from(
        (data['mutationIds'] as List?) ?? const <String>[],
      ),
      error: data['error'] as String?,
      startedAt: DateTime.parse(data['startedAt'] as String),
      completedAt: DateTime.parse(data['completedAt'] as String),
    );
  }
}
