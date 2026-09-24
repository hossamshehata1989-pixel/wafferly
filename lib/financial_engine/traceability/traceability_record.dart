/// Immutable audit record for a Financial Operation execution.
///
/// Traceability is History / Audit state. It never becomes a source of
/// Financial Reality and must not be used to calculate balances.
final class TraceabilityRecord {
  final String traceId;
  final String operationType;
  final String? operationId;
  final String idempotencyKey;
  final String status;
  final String? actorMemberId;
  final String? source;
  final String? commitmentId;
  final String? scheduleRuleId;
  final String? occurrenceId;
  final List<String> transactionIds;
  final List<String> mutationIds;
  final String? error;
  final DateTime startedAt;
  final DateTime completedAt;

  const TraceabilityRecord({
    required this.traceId,
    required this.operationType,
    this.operationId,
    required this.idempotencyKey,
    required this.status,
    this.actorMemberId,
    this.source,
    this.commitmentId,
    this.scheduleRuleId,
    this.occurrenceId,
    this.transactionIds = const <String>[],
    this.mutationIds = const <String>[],
    this.error,
    required this.startedAt,
    required this.completedAt,
  });
}
