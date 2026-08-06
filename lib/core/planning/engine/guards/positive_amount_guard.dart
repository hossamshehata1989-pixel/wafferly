import '../../operations/reserve_operation.dart';
import '../planning_execution_context.dart';
import 'planning_guard.dart';

/// ===============================================================
/// PositiveAmountGuard
/// ===============================================================
///
/// Ensures that reserve amounts are strictly positive.
///
/// ===============================================================
final class PositiveAmountGuard implements PlanningGuard {
  const PositiveAmountGuard();

  @override
  Future<void> validate(PlanningExecutionContext context) async {
    switch (context.operation) {
      case ReserveOperation operation:
        if (operation.amount <= 0) {
          throw ArgumentError('Reserve amount must be greater than zero.');
        }
    }
  }
}
