import '../../operations/release_operation.dart';
import '../../ports/allocation_repository.dart';
import '../planning_execution_context.dart';
import 'planning_guard.dart';

/// ===============================================================
/// CannotReleaseMoreThanReservedGuard
/// ===============================================================
///
/// Prevents releasing more money than currently reserved.
///
/// ===============================================================
final class CannotReleaseMoreThanReservedGuard implements PlanningGuard {
  const CannotReleaseMoreThanReservedGuard({required this.repository});

  final AllocationRepository repository;

  @override
  Future<void> validate(PlanningExecutionContext context) async {
    switch (context.operation) {
      case ReleaseOperation operation:
        final allocation = await repository.findCurrentBySource(
          operation.sourceId,
        );

        if (allocation == null) {
          throw StateError('No allocation exists for this planning source.');
        }

        if (operation.amount > allocation.amount) {
          throw StateError('Cannot release more than reserved amount.');
        }

      default:
        break;
    }
  }
}
