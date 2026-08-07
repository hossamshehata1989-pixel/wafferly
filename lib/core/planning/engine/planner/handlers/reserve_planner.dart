import '../../../operations/reserve_operation.dart';
import '../../planning_execution_context.dart';
import '../planning_execution_plan.dart';
import '../planning_mutation.dart';
import '../../../ports/allocation_id_generator.dart';
import 'planning_operation_handler.dart';

final class ReservePlanner implements PlanningOperationHandler {
  const ReservePlanner({required this.idGenerator});

  final AllocationIdGenerator idGenerator;

  @override
  Future<PlanningExecutionPlan> plan(PlanningExecutionContext context) async {
    final operation = context.operation as ReserveOperation;

    return PlanningExecutionPlan(
      mutations: [
        CreateAllocationMutation(
          allocationId: idGenerator.next(),
          createdAt: operation.createdAt,
          sourceId: operation.sourceId,
          sourceType: operation.sourceType,
          accountId: operation.accountId,
          amount: operation.amount,
        ),
      ],
    );
  }
}
