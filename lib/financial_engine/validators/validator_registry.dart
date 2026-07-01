import 'balance_validator.dart';
import 'financial_validator.dart';

final class ValidatorRegistry {
  const ValidatorRegistry();

  List<FinancialValidator> get validators => const [BalanceValidator()];
}
