import '../../operations/reserve_operation.dart';
import '../../operations/release_operation.dart';
import '../planning_execution_context.dart';
import 'execution_planner.dart';
import 'planning_execution_plan.dart';
import 'planning_mutation.dart';

final class DefaultPlanningPlanner implements ExecutionPlanner {
  const DefaultPlanningPlanner();

  @override
  Future<PlanningExecutionPlan> plan(PlanningExecutionContext context) async {
    switch (context.operation) {
      case ReserveOperation operation:
        return PlanningExecutionPlan(
          mutations: [
            CreateAllocationMutation(
              allocationId: operation.id,
              createdAt: operation.createdAt,
              sourceId: operation.sourceId,
              sourceType: operation.sourceType,
              accountId: operation.accountId,
              amount: operation.amount,
            ),
          ],
        );

      case ReleaseOperation operation:
        return PlanningExecutionPlan(
          mutations: [
            DecreaseAllocationMutation(
              allocationId: operation.id,
              amount: operation.amount,
            ),
          ],
        );
    }

    throw UnsupportedError(
      'Unsupported planning operation: ${context.operation.runtimeType}',
    );
  }
}
