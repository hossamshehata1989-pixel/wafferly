import '../operations/financial_operation.dart';
import 'validation_result.dart';
import 'validator_registry.dart';

final class ValidationPipeline {
  final ValidatorRegistry registry;

  const ValidationPipeline({required this.registry});

  Future<ValidationResult> validate(FinancialOperation operation) async {
    for (final validator in registry.validators) {
      final result = await validator.validate(operation);

      if (result is ValidationFailureResult) {
        return result;
      }
    }

    return const ValidationSucceeded();
  }
}
