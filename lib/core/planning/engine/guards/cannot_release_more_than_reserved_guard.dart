import '../../operations/release_operation.dart';
import '../../ports/allocation_repository.dart';
import '../planning_execution_context.dart';
import 'planning_guard.dart';
import '../../value_objects/allocation_status.dart';

/// ===============================================================
/// CannotReleaseMoreThanReservedGuard
/// ===============================================================
///
/// Prevents releasing more money than currently reserved.
///
/// A planning source may have multiple active allocations.
/// Therefore, the guard validates against the TOTAL active
/// reserved amount for the requested source + account.
///
/// The guard does not modify state.
/// ===============================================================
final class CannotReleaseMoreThanReservedGuard implements PlanningGuard {
  const CannotReleaseMoreThanReservedGuard({required this.repository});

  final AllocationRepository repository;

  @override
  Future<void> validate(PlanningExecutionContext context) async {
    switch (context.operation) {
      case ReleaseOperation operation:
        final allocations = await repository.findBySource(operation.sourceId);

        final totalReserved = allocations
            .where(
              (allocation) =>
                  allocation.status == AllocationStatus.active &&
                  allocation.accountId == operation.accountId &&
                  allocation.amount > 0,
            )
            .fold<double>(0, (sum, allocation) => sum + allocation.amount);

        if (totalReserved <= 0) {
          throw StateError(
            'No active allocation exists for this planning source '
            'and account.',
          );
        }

        if (operation.amount > totalReserved) {
          throw StateError(
            'Cannot release more than reserved amount. '
            'Reserved: $totalReserved, Requested: ${operation.amount}.',
          );
        }

      default:
        break;
    }
  }
}
