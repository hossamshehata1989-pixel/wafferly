import '../operations/planning_operation.dart';
import 'interpreter/planning_interpreter.dart';
import 'planner/planning_execution_plan.dart';

/// ===============================================================
/// PlanningExecutionContext
/// ===============================================================
///
/// Carries all execution state across the Planning Engine pipeline.
///
/// The context is progressively enriched as it flows through:
///
/// Operation
///     ↓
/// Interpreter
///     ↓
/// Guards
///     ↓
/// Policies
///     ↓
/// Planner
///     ↓
/// Integrity
///     ↓
/// Executor
///
/// ===============================================================
final class PlanningExecutionContext {
  const PlanningExecutionContext({
    required this.operation,
    required this.intent,
    this.plan,
  });

  /// Original immutable operation.
  final PlanningOperation operation;

  /// Internal engine intent.
  final PlanningIntent intent;

  final PlanningExecutionPlan? plan;

  PlanningExecutionContext copyWith({
    PlanningOperation? operation,
    PlanningIntent? intent,
    PlanningExecutionPlan? plan,
  }) {
    return PlanningExecutionContext(
      operation: operation ?? this.operation,
      intent: intent ?? this.intent,
      plan: plan ?? this.plan,
    );
  }
}
