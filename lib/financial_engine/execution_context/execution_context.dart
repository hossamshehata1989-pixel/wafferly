final class ExecutionContext {
  final String idempotencyKey;

  /// Optional linkage to the scheduled financial action that triggered
  /// this execution.
  final String? commitmentId;
  final String? scheduleRuleId;
  final String? occurrenceId;

  /// Optional traceability attribution supplied by the initiating boundary.
  final String? actorMemberId;
  final String? source;
  final String? commandType;

  const ExecutionContext({
    required this.idempotencyKey,
    this.commitmentId,
    this.scheduleRuleId,
    this.occurrenceId,
    this.actorMemberId,
    this.source,
    this.commandType,
  });
}
