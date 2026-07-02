import '../operations/financial_operation.dart';
import '../providers/balance_provider.dart';
import 'financial_validator.dart';

import 'validation_result.dart';

final class BalanceValidator implements FinancialValidator {
  final BalanceProvider _balanceProvider;

  const BalanceValidator({required BalanceProvider balanceProvider})
    : _balanceProvider = balanceProvider;

  @override
  Future<ValidationResult> validate(FinancialOperation operation) async {
    // TODO(ADR):
    // Read source account from the operation.
    // Query available balance.
    // Compare with requested amount.
    // Return ValidationFailureResult when insufficient.

    return const ValidationSucceeded();
  }
}
