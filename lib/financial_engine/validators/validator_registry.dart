import 'financial_validator.dart';

final class ValidatorRegistry {
  final List<FinancialValidator> validators;

  const ValidatorRegistry({required this.validators});
}
