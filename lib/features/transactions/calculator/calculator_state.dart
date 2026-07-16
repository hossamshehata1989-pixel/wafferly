class CalculatorState {
  final String expression;

  final bool justCalculated;

  const CalculatorState({
    required this.expression,
    this.justCalculated = false,
  });

  CalculatorState copyWith({String? expression, bool? justCalculated}) {
    return CalculatorState(
      expression: expression ?? this.expression,
      justCalculated: justCalculated ?? this.justCalculated,
    );
  }

  static const initial = CalculatorState(expression: '0');
}
