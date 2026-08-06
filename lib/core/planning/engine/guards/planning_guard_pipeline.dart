import '../planning_execution_context.dart';
import 'planning_guard.dart';

/// ===============================================================
/// PlanningGuardPipeline
/// ===============================================================
///
/// Executes all registered guards.
///
/// Stops immediately on the first failure.
///
/// ===============================================================
final class PlanningGuardPipeline {
  const PlanningGuardPipeline({required this.guards});

  final List<PlanningGuard> guards;

  Future<void> validate(PlanningExecutionContext context) async {
    for (final guard in guards) {
      await guard.validate(context);
    }
  }
}
