sealed class PolicyResult {
  const PolicyResult();
}

final class PolicyPassed extends PolicyResult {
  const PolicyPassed();
}

final class PolicyRejected extends PolicyResult {
  final String reason;

  const PolicyRejected({required this.reason});
}

final class PolicyRequiresConfirmation extends PolicyResult {
  const PolicyRequiresConfirmation();
}
