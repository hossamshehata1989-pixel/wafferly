import '../planning_execution_context.dart';
import '../interpreter/planning_interpreter.dart';
import '../../operations/reserve_operation.dart';
import '../../services/available_balance_projection_service.dart';
import 'planning_guard.dart';

/// ===============================================================
/// CannotReserveMoreThanAvailableGuard
/// ===============================================================
///
/// Prevents a reservation from exceeding the account's currently
/// available balance.
///
/// Financial balance comes from the Financial side.
/// Reserved money comes from active Planning Allocations.
///
/// Formula:
///
///   available = accountBalance - activeReservations
///
/// The guard only validates.
/// It never mutates state.
/// ===============================================================
final class CannotReserveMoreThanAvailableGuard implements PlanningGuard {
  const CannotReserveMoreThanAvailableGuard({
    required this.availableBalanceProjectionService,
    required this.accountBalanceProvider,
  });

  final AvailableBalanceProjectionService availableBalanceProjectionService;

  /// Returns the actual financial account balance.
  final double Function(String accountId) accountBalanceProvider;

  @override
  Future<void> validate(PlanningExecutionContext context) async {
    if (context.intent != PlanningIntent.reserve) {
      return;
    }

    final operation = context.operation;

    if (operation is! ReserveOperation) {
      return;
    }

    final accountBalance = accountBalanceProvider(operation.accountId);

    final projection = await availableBalanceProjectionService.project(
      accountId: operation.accountId,
      balance: accountBalance,
    );

    if (operation.amount > projection.available) {
      throw StateError(
        'Insufficient available balance for reservation. '
        'Account: ${operation.accountId}. '
        'Available: ${projection.available}. '
        'Requested: ${operation.amount}.',
      );
    }
  }
}
