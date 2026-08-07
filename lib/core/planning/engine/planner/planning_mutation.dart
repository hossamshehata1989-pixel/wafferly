import '../../value_objects/planning_source_type.dart';

/// ===============================================================
/// PlanningMutation
/// ===============================================================
///
/// Represents a single domain mutation produced by the Planner.
///
/// Mutations are immutable execution primitives understood by the
/// Planning Executor.
///
/// They are NOT database operations.
/// They represent domain-level allocation changes.
///
/// ===============================================================
sealed class PlanningMutation {
  const PlanningMutation();
}

/// ===============================================================
/// ReserveMutation
/// ===============================================================
final class ReserveMutation extends PlanningMutation {
  const ReserveMutation({
    required this.sourceId,
    required this.sourceType,
    required this.accountId,
    required this.amount,
  });

  final String sourceId;

  final PlanningSourceType sourceType;
  final String accountId;

  final double amount;
}

/// ===============================================================
/// ReleaseMutation
/// ===============================================================
final class ReleaseMutation extends PlanningMutation {
  const ReleaseMutation({required this.sourceId, required this.amount});

  final String sourceId;

  final double amount;
}
