import '../domain_guard/financial_constraint.dart';
import '../planning/planning_context.dart';
import '../resolution/resolution.dart';
import '../interpretation/normalized_intent.dart';

abstract class FinancialOperation {
  final Resolution? resolution;

  const FinancialOperation({this.resolution});

  bool get hasResolution => resolution != null;

  FinancialOperation resolve(Resolution resolution);

  PlanningContext createPlanningContext({
    required NormalizedIntent intent,
    required List<FinancialConstraint> constraints,
  });
}
