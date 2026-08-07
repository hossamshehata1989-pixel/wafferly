import '../../value_objects/planning_source_type.dart';

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

  final double amount;
}

/// ===============================================================
/// IncreaseAllocationMutation
/// ===============================================================
final class IncreaseAllocationMutation extends PlanningMutation {
  const IncreaseAllocationMutation({
    required this.allocationId,
    required this.amount,
  });

  final String allocationId;

  final double amount;
}

/// ===============================================================
/// DecreaseAllocationMutation
/// ===============================================================
final class DecreaseAllocationMutation extends PlanningMutation {
  const DecreaseAllocationMutation({
    required this.allocationId,
    required this.amount,
  });

  final String allocationId;

  final double amount;
}

/// ===============================================================
/// DeactivateAllocationMutation
/// ===============================================================
final class DeactivateAllocationMutation extends PlanningMutation {
  const DeactivateAllocationMutation({required this.allocationId});

  final String allocationId;
}
