import 'validation_failure.dart';

sealed class ValidationResult {
  const ValidationResult();
}

class ValidationSucceeded extends ValidationResult {
  const ValidationSucceeded();
}

final class ValidationFailureResult extends ValidationResult {
  final ValidationFailure failure;

  const ValidationFailureResult(this.failure);
}
