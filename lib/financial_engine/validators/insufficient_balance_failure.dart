import 'validation_failure.dart';

final class InsufficientBalanceFailure extends ValidationFailure {
  final double required;
  final double available;

  const InsufficientBalanceFailure({
    required this.required,
    required this.available,
  });
}
