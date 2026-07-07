import 'domain_guard_result.dart';
import 'financial_constraint.dart';

final class DomainGuardPipelineResult {
  final DomainViolation? violation;
  final List<FinancialConstraint> constraints;

  const DomainGuardPipelineResult({
    this.violation,
    this.constraints = const [],
  });

  bool get hasViolation => violation != null;

  bool get hasConstraints => constraints.isNotEmpty;
}
