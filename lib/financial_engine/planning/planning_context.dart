import '../domain_guard/financial_constraint.dart';
import '../interpretation/normalized_intent.dart';

final class PlanningContext {
  final NormalizedIntent intent;

  final List<FinancialConstraint> constraints;

  const PlanningContext({required this.intent, this.constraints = const []});

  T? constraint<T extends FinancialConstraint>() {
    for (final constraint in constraints) {
      if (constraint is T) {
        return constraint;
      }
    }

    return null;
  }
}
