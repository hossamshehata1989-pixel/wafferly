// lib/features/transactions/calculator/calculator_engine.dart

import 'package:math_expressions/math_expressions.dart';
import 'calculator_state.dart';

class CalculatorEngine {
  /// Processes a single key press and returns the new state.
  CalculatorState press(CalculatorState state, String key) {
    // Clear
    if (key == 'C') {
      return CalculatorState.initial;
    }

    // Backspace
    if (key == '⌫') {
      final expr = state.expression;
      if (expr.length > 1) {
        return state.copyWith(expression: expr.substring(0, expr.length - 1));
      } else {
        return CalculatorState.initial;
      }
    }

    // Equals
    if (key == '=') {
      try {
        final parser = Parser();
        final expression = parser.parse(state.expression.replaceAll('x', '*'));
        final result = expression.evaluate(EvaluationType.REAL, ContextModel());
        final newExpr = result % 1 == 0
            ? result.toInt().toString()
            : result.toString();
        return CalculatorState(expression: newExpr, justCalculated: true);
      } catch (_) {
        return CalculatorState.initial;
      }
    }

    // Normal input (numbers and operators)
    final expr = state.expression;
    final justCalcd = state.justCalculated;

    // If just calculated, start fresh with number, or append operator
    if (justCalcd) {
      if (_isOperator(key)) {
        return state.copyWith(expression: expr + key, justCalculated: false);
      } else {
        return CalculatorState(expression: key);
      }
    }

    // Prevent starting with an operator when expression is "0"
    if (expr == '0') {
      if (!_isOperator(key)) {
        return CalculatorState(expression: key);
      }
      // ignore operator, return same state
      return state;
    }

    // Operator replacement: if last char is operator and new key is operator, replace.
    final lastChar = expr.isNotEmpty ? expr[expr.length - 1] : '';
    if (_isOperator(lastChar) && _isOperator(key)) {
      return state.copyWith(
        expression: expr.substring(0, expr.length - 1) + key,
      );
    }

    // Append
    return state.copyWith(expression: expr + key);
  }

  bool _isOperator(String value) {
    return value == '+' ||
        value == '-' ||
        value == '*' ||
        value == '/' ||
        value == 'x';
  }
}
