import '../../core/money/money.dart';
sealed class FinancialConstraint {
  const FinancialConstraint();
}

final class InsufficientBalanceConstraint extends FinancialConstraint {
  final Money available;
  final Money required;

  const InsufficientBalanceConstraint({
    required this.available,
    required this.required,
  });
}
