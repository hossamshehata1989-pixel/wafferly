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
