import '../../operations/planning_operation.dart';
import '../../operations/reserve_operation.dart';

import 'planning_interpreter.dart';
import '../../operations/release_operation.dart';

/// ===============================================================
/// DefaultPlanningInterpreter
/// ===============================================================
///
/// Default implementation of PlanningInterpreter.
///
/// ===============================================================
final class DefaultPlanningInterpreter implements PlanningInterpreter {
  const DefaultPlanningInterpreter();

  @override
  PlanningIntent interpret(PlanningOperation operation) {
    switch (operation) {
      case ReserveOperation():
        return PlanningIntent.reserve;

      case ReleaseOperation():
        return PlanningIntent.release;
    }

    throw UnsupportedError(
      'Unsupported PlanningOperation: ${operation.runtimeType}',
    );
  }
}
