import '../../operations/merge_operation.dart';
import '../../operations/release_operation.dart';
import '../../operations/reserve_operation.dart';
import '../../operations/split_operation.dart';

import '../planning_execution_context.dart';

import 'execution_planner.dart';
import 'handlers/merge_planner.dart';
import 'handlers/release_planner.dart';
import 'handlers/reserve_planner.dart';
import 'handlers/split_planner.dart';
import 'planning_execution_plan.dart';

final class DefaultPlanningPlanner implements ExecutionPlanner {
  const DefaultPlanningPlanner({
    required this.reservePlanner,
    required this.releasePlanner,
    required this.splitPlanner,
    required this.mergePlanner,
  });

  final ReservePlanner reservePlanner;
  final ReleasePlanner releasePlanner;
  final SplitPlanner splitPlanner;
  final MergePlanner mergePlanner;

  @override
  Future<PlanningExecutionPlan> plan(PlanningExecutionContext context) {
    return switch (context.operation) {
      ReserveOperation() => reservePlanner.plan(context),
      ReleaseOperation() => releasePlanner.plan(context),
      SplitOperation() => splitPlanner.plan(context),
      MergeOperation() => mergePlanner.plan(context),
      _ => throw UnsupportedError(
        'Unsupported planning operation: '
        '${context.operation.runtimeType}',
      ),
    };
  }
}
