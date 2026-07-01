import '../operations/financial_operation.dart';
import 'validation_result.dart';

abstract class FinancialValidator {
  const FinancialValidator();

  Future<ValidationResult> validate(FinancialOperation operation);
}
