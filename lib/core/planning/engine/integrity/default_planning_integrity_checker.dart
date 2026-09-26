import '../../../../core/money/money.dart';

import '../planner/planning_execution_plan.dart';
import '../planner/planning_mutation.dart';

import 'planning_integrity_checker.dart';

/// ===============================================================
/// DefaultPlanningIntegrityChecker
/// ===============================================================
///
/// Validates the final PlanningExecutionPlan immediately before
/// execution.
///
/// Responsibilities:
/// - Validate the structural integrity of the complete plan.
/// - Validate mutation payloads.
/// - Validate mutation ordering constraints that can be proven
///   without accessing repositories or external state.
///
/// This checker intentionally does NOT:
/// - validate business rules owned by Guards,
/// - make planning decisions,
/// - access AllocationRepository,
/// - calculate available balance,
/// - mutate any state,
/// - execute mutations.
///
/// ===============================================================
final class DefaultPlanningIntegrityChecker
    implements PlanningIntegrityChecker {
  const DefaultPlanningIntegrityChecker();

  @override
  Future<void> validate(PlanningExecutionPlan plan) async {
    _validatePlan(plan);
  }

  // ===============================================================
  // Plan validation
  // ===============================================================

  void _validatePlan(PlanningExecutionPlan plan) {
    if (plan.mutations.isEmpty) {
      throw StateError(
        'Planning execution plan must contain at least one mutation.',
      );
    }

    final deactivatedAllocationIds = <String>{};

    for (var index = 0; index < plan.mutations.length; index++) {
      final mutation = plan.mutations[index];

      switch (mutation) {
        case CreateAllocationMutation():
          _validateCreateMutation(
            mutation,
            index: index,
            deactivatedAllocationIds: deactivatedAllocationIds,
          );

        case IncreaseAllocationMutation():
          _validateIncreaseMutation(
            mutation,
            index: index,
            deactivatedAllocationIds: deactivatedAllocationIds,
          );

        case DecreaseAllocationMutation():
          _validateDecreaseMutation(
            mutation,
            index: index,
            deactivatedAllocationIds: deactivatedAllocationIds,
          );

        case DeactivateAllocationMutation():
          _validateDeactivateMutation(
            mutation,
            index: index,
            deactivatedAllocationIds: deactivatedAllocationIds,
          );

        case RestoreAllocationMutation():
          _validateRestoreMutation(mutation, index: index);
      }
    }
  }

  // ===============================================================
  // Create
  // ===============================================================

  void _validateCreateMutation(
    CreateAllocationMutation mutation, {
    required int index,
    required Set<String> deactivatedAllocationIds,
  }) {
    _requireNonBlank(
      mutation.allocationId,
      field: 'allocationId',
      mutationIndex: index,
    );

    _requireNonBlank(
      mutation.sourceId,
      field: 'sourceId',
      mutationIndex: index,
    );

    _requireNonBlank(
      mutation.accountId,
      field: 'accountId',
      mutationIndex: index,
    );

    _requirePositiveAmount(
      mutation.amount,
      field: 'amount',
      mutationIndex: index,
    );

    if (deactivatedAllocationIds.contains(mutation.allocationId)) {
      throw StateError(
        'Invalid planning execution plan at mutation $index: '
        'allocation "${mutation.allocationId}" is already deactivated.',
      );
    }
  }

  // ===============================================================
  // Increase
  // ===============================================================

  void _validateIncreaseMutation(
    IncreaseAllocationMutation mutation, {
    required int index,
    required Set<String> deactivatedAllocationIds,
  }) {
    _requireNonBlank(
      mutation.allocationId,
      field: 'allocationId',
      mutationIndex: index,
    );

    _requirePositiveAmount(
      mutation.amount,
      field: 'amount',
      mutationIndex: index,
    );

    _ensureNotDeactivated(
      allocationId: mutation.allocationId,
      mutationIndex: index,
      deactivatedAllocationIds: deactivatedAllocationIds,
    );
  }

  // ===============================================================
  // Decrease
  // ===============================================================

  void _validateDecreaseMutation(
    DecreaseAllocationMutation mutation, {
    required int index,
    required Set<String> deactivatedAllocationIds,
  }) {
    _requireNonBlank(
      mutation.allocationId,
      field: 'allocationId',
      mutationIndex: index,
    );

    _requirePositiveAmount(
      mutation.amount,
      field: 'amount',
      mutationIndex: index,
    );

    _ensureNotDeactivated(
      allocationId: mutation.allocationId,
      mutationIndex: index,
      deactivatedAllocationIds: deactivatedAllocationIds,
    );
  }

  // ===============================================================
  // Deactivate
  // ===============================================================

  void _validateDeactivateMutation(
    DeactivateAllocationMutation mutation, {
    required int index,
    required Set<String> deactivatedAllocationIds,
  }) {
    _requireNonBlank(
      mutation.allocationId,
      field: 'allocationId',
      mutationIndex: index,
    );

    if (!deactivatedAllocationIds.add(mutation.allocationId)) {
      throw StateError(
        'Invalid planning execution plan at mutation $index: '
        'allocation "${mutation.allocationId}" is deactivated more than once.',
      );
    }
  }

  void _validateRestoreMutation(
    RestoreAllocationMutation mutation, {
    required int index,
  }) {
    _requireNonBlank(
      mutation.allocation.id,
      field: 'allocation.id',
      mutationIndex: index,
    );

    _requireNonBlank(
      mutation.allocation.sourceId,
      field: 'allocation.sourceId',
      mutationIndex: index,
    );

    _requireNonBlank(
      mutation.allocation.accountId,
      field: 'allocation.accountId',
      mutationIndex: index,
    );

    if (mutation.allocation.amount < Money.zero) {
      throw StateError(
        'Invalid planning execution plan at mutation $index: '
        'allocation.amount must not be negative.',
      );
    }
  }

  // ===============================================================
  // Shared validation helpers
  // ===============================================================

  void _requireNonBlank(
    String value, {
    required String field,
    required int mutationIndex,
  }) {
    if (value.trim().isEmpty) {
      throw StateError(
        'Invalid planning execution plan at mutation $mutationIndex: '
        '$field must not be blank.',
      );
    }
  }

  void _requirePositiveAmount(
    Money amount, {
    required String field,
    required int mutationIndex,
  }) {
    if (amount <= Money.zero) {
      throw StateError(
        'Invalid planning execution plan at mutation $mutationIndex: '
        '$field must be greater than zero.',
      );
    }
  }

  void _ensureNotDeactivated({
    required String allocationId,
    required int mutationIndex,
    required Set<String> deactivatedAllocationIds,
  }) {
    if (deactivatedAllocationIds.contains(allocationId)) {
      throw StateError(
        'Invalid planning execution plan at mutation $mutationIndex: '
        'allocation "$allocationId" is already deactivated.',
      );
    }
  }
}