import '../operations/financial_operation.dart';
import 'normalized_intent.dart';

/// Converts a FinancialOperation into a normalized internal representation.
///
/// This layer performs translation only.
/// It MUST NOT:
/// - validate domain rules
/// - evaluate business policies
/// - access persistence
/// - execute mutations
abstract interface class FinancialInterpreter {
  NormalizedIntent interpret(FinancialOperation operation);
}
