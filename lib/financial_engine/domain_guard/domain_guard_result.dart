import 'financial_constraint.dart';

sealed class DomainGuardResult {
  const DomainGuardResult();
}

final class DomainGuardPassed extends DomainGuardResult {
  const DomainGuardPassed();
}

final class DomainViolation extends DomainGuardResult {
  final String reason;

  const DomainViolation({required this.reason});
}

final class DomainConstraint extends DomainGuardResult {
  final FinancialConstraint constraint;

  const DomainConstraint({required this.constraint});
}
