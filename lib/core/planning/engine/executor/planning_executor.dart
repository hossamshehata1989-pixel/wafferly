import '../planning_execution_context.dart';

/// ===============================================================
/// PlanningExecutor
/// ===============================================================
///
/// Executes validated PlanningOperations.
///
/// The Executor is the only component allowed
/// to mutate Allocation state.
///
/// Responsibilities:
/// - Create Allocations
/// - Update Allocations
/// - Release Allocations
/// - Reallocate Allocations
///
/// It owns NO business rules.
///
/// ADR References:
/// - ADR-026 PlanningOperation Contract
/// - ADR-028 Allocation Contract
///
/// ===============================================================
abstract interface class PlanningExecutor {
  Future<void> execute(PlanningExecutionContext context);
}
