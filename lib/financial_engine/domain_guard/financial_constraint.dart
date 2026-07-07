sealed class FinancialConstraint {
  const FinancialConstraint();
}

final class InsufficientBalanceConstraint extends FinancialConstraint {
  final double available;
  final double required;

  const InsufficientBalanceConstraint({
    required this.available,
    required this.required,
  });
}
