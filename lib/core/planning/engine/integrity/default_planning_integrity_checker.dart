import '../planner/planning_execution_plan.dart';

import 'planning_integrity_checker.dart';

/// ===============================================================
/// DefaultPlanningIntegrityChecker
/// ===============================================================
final class DefaultPlanningIntegrityChecker
    implements PlanningIntegrityChecker {
  const DefaultPlanningIntegrityChecker();

  @override
  Future<void> validate(PlanningExecutionPlan plan) async {
    // No integrity rules yet.
  }
}
