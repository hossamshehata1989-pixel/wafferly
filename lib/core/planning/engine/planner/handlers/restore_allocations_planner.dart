import '../../../operations/restore_allocations_operation.dart';
import '../../planning_execution_context.dart';
import '../planning_execution_plan.dart';
import '../planning_mutation.dart';
import 'planning_operation_handler.dart';

/// Plans exact Allocation-state restoration for financial compensation.
///
/// This planner never mutates the repository. The actual writes remain
/// exclusively inside DefaultPlanningExecutor.
final class RestoreAllocationsPlanner implements PlanningOperationHandler {
  const RestoreAllocationsPlanner();

  @override
  Future<PlanningExecutionPlan> plan(PlanningExecutionContext context) async {
    final operation = context.operation as RestoreAllocationsOperation;

    if (operation.snapshots.isEmpty) {
      throw StateError('Allocation restoration requires at least one snapshot.');
    }

    return PlanningExecutionPlan(
      mutations: operation.snapshots
          .map((allocation) => RestoreAllocationMutation(allocation: allocation))
          .toList(growable: false),
    );
  }
}
