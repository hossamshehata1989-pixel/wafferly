import '../operations/planning_operation.dart';

import 'executor/planning_executor.dart';
import 'guards/planning_guard_pipeline.dart';
import 'integrity/planning_integrity_checker.dart';
import 'interpreter/planning_interpreter.dart';
import 'planner/execution_planner.dart';
import 'planning_execution_context.dart';
import 'policies/planning_policy_pipeline.dart';

/// ===============================================================
/// PlanningEngine
/// ===============================================================
///
/// Coordinates the complete Planning execution pipeline.
///
/// Pipeline:
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
final class PlanningEngine {
  const PlanningEngine({
    required this.interpreter,
    required this.guards,
    required this.policies,
    required this.planner,
    required this.integrity,
    required this.executor,
  });

  final PlanningInterpreter interpreter;

  final PlanningGuardPipeline guards;

  final PlanningPolicyPipeline policies;

  final ExecutionPlanner planner;

  final PlanningIntegrityChecker integrity;

  final PlanningExecutor executor;

  /// Receives the final validated operation
  /// after Guards, Policies and Planning.

  Future<void> execute(PlanningOperation operation) async {
    final intent = interpreter.interpret(operation);

    var context = PlanningExecutionContext(
      operation: operation,
      intent: intent,
    );

    await guards.validate(context);

    context = await policies.apply(context);

    final plan = await planner.plan(context);

    await integrity.validate(plan);

    await integrity.validate(plan);

    await executor.execute(plan);
  }
}
