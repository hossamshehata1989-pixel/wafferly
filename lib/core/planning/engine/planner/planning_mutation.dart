import '../../value_objects/planning_source_type.dart';
import '../../entities/allocation.dart';
import '../../../../core/money/money.dart';
sealed class PlanningMutation {
  const PlanningMutation();
}

/// ===============================================================
/// CreateAllocationMutation
/// ===============================================================
final class CreateAllocationMutation extends PlanningMutation {
  const CreateAllocationMutation({
    required this.allocationId,
    required this.createdAt,
    required this.sourceId,
    required this.sourceType,
    required this.accountId,
    required this.amount,
  });

  final String allocationId;
  final DateTime createdAt;

  final String sourceId;
  final PlanningSourceType sourceType;
  final String accountId;

final Money amount;}

/// ===============================================================
/// IncreaseAllocationMutation
/// ===============================================================
final class IncreaseAllocationMutation extends PlanningMutation {
  const IncreaseAllocationMutation({
    required this.allocationId,
    required this.amount,
  });

  final String allocationId;

final Money amount;}

/// ===============================================================
/// DecreaseAllocationMutation
/// ===============================================================
final class DecreaseAllocationMutation extends PlanningMutation {
  const DecreaseAllocationMutation({
    required this.allocationId,
    required this.amount,
  });

  final String allocationId;

final Money amount;}

/// ===============================================================
/// DeactivateAllocationMutation
/// ===============================================================
final class DeactivateAllocationMutation extends PlanningMutation {
  const DeactivateAllocationMutation({required this.allocationId});

  final String allocationId;
}


/// Restores an exact Allocation snapshot as a compensation mutation.
///
/// This is intentionally executed only by DefaultPlanningExecutor so no
/// caller outside the Planning Engine can mutate AllocationRepository.
final class RestoreAllocationMutation extends PlanningMutation {
  const RestoreAllocationMutation({required this.allocation});

  final Allocation allocation;
}
