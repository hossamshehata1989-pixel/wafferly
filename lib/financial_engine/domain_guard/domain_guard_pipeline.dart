import '../interpretation/normalized_intent.dart';
import 'domain_guard.dart';
import 'domain_guard_pipeline_result.dart';
import 'domain_guard_result.dart';
import 'financial_constraint.dart';

final class DomainGuardPipeline {
  final List<DomainGuard> _guards;

  const DomainGuardPipeline({List<DomainGuard> guards = const []})
    : _guards = guards;

  Future<DomainGuardPipelineResult> validate(NormalizedIntent intent) async {
    final constraints = <FinancialConstraint>[];

    for (final guard in _guards) {
      final result = await guard.validate(intent);

      switch (result) {
        case DomainGuardPassed():
          break;

        case DomainConstraint():
          constraints.add(result.constraint);
          break;

        case DomainViolation():
          return DomainGuardPipelineResult(
            violation: result,
            constraints: constraints,
          );
      }
    }

    return DomainGuardPipelineResult(constraints: constraints);
  }
}
