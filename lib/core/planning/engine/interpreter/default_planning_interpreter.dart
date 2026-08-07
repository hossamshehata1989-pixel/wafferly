import '../../operations/planning_operation.dart';
import '../../operations/reserve_operation.dart';
import '../../operations/release_operation.dart';
import '../../operations/split_operation.dart';
import '../../operations/merge_operation.dart';

import 'planning_interpreter.dart';

final class DefaultPlanningInterpreter implements PlanningInterpreter {
  const DefaultPlanningInterpreter();

  @override
  PlanningIntent interpret(PlanningOperation operation) {
    return switch (operation) {
      ReserveOperation() => PlanningIntent.reserve,
      ReleaseOperation() => PlanningIntent.release,
      SplitOperation() => PlanningIntent.split,
      MergeOperation() => PlanningIntent.merge,
      _ => throw UnsupportedError(
        'Unsupported planning operation: ${operation.runtimeType}',
      ),
    };
  }
}
