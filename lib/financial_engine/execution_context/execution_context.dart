final class ExecutionContext {
  final String idempotencyKey;

  /// Optional linkage to the scheduled financial action that triggered
  /// this execution.
  final String? commitmentId;
  final String? scheduleRuleId;
  final String? occurrenceId;

  const ExecutionContext({
    required this.idempotencyKey,
    this.commitmentId,
    this.scheduleRuleId,
    this.occurrenceId,
  });
}
