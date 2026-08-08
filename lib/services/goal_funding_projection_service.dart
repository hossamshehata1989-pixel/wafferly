import '../core/planning/ports/allocation_repository.dart';
import '../core/planning/value_objects/allocation_status.dart';
import '../core/planning/value_objects/planning_source_type.dart';
import '../models/goal_activity.dart';
import '../models/goal_funding_source.dart';
import '../models/goal_funding_projection.dart';
import 'goal_activity_service.dart';
import 'account_service.dart';

class GoalFundingProjectionService {
  GoalFundingProjectionService({
    required AllocationRepository allocationRepository,
  }) : _allocationRepository = allocationRepository;

  final AllocationRepository _allocationRepository;

  final GoalActivityService _activityService = GoalActivityService();
  final AccountService _accountService = AccountService();

  /// Returns the currently active Planning allocations for this Goal,
  /// grouped by funding account.
  Future<List<GoalFundingSource>> getFundingSources(String goalId) async {
    final allocations = await _allocationRepository.findBySource(goalId);

    final activeGoalAllocations = allocations.where(
      (allocation) =>
          allocation.sourceType == PlanningSourceType.goal &&
          allocation.status == AllocationStatus.active,
    );

    final Map<String, double> totals = {};

    for (final allocation in activeGoalAllocations) {
      totals[allocation.accountId] =
          (totals[allocation.accountId] ?? 0) + allocation.amount;
    }

    return totals.entries.map((entry) {
      final account = _accountService.getAccountById(entry.key);

      return GoalFundingSource(
        accountId: entry.key,
        accountName: account?.name ?? 'Unknown',
        amount: entry.value,
        isSaving: false,
      );
    }).toList();
  }

  /// Returns historical amounts transferred to saving.
  List<GoalFundingSource> getSavedSources(String goalId) {
    final activities = _activityService.getGoalActivities(goalId);

    final Map<String, double> totals = {};

    for (final activity in activities) {
      if (activity.type == GoalActivityType.transferToSaving) {
        final accountId = activity.destinationAccountId;

        if (accountId != null) {
          totals[accountId] = (totals[accountId] ?? 0) + activity.amount;
        }
      }
    }

    return totals.entries.map((entry) {
      final account = _accountService.getAccountById(entry.key);

      return GoalFundingSource(
        accountId: entry.key,
        accountName: account?.name ?? 'Unknown',
        amount: entry.value,
        isSaving: true,
      );
    }).toList();
  }

  /// Full Goal projection:
  ///
  /// Reserved  -> Planning Allocation state
  /// Saved     -> historical GoalActivity state
  Future<GoalFundingProjection> getProjection(String goalId) async {
    final reservedSources = await getFundingSources(goalId);
    final savedSources = getSavedSources(goalId);

    final totalReserved = reservedSources.fold<double>(
      0,
      (sum, source) => sum + source.amount,
    );

    final totalSaved = savedSources.fold<double>(
      0,
      (sum, source) => sum + source.amount,
    );

    return GoalFundingProjection(
      reservedSources: reservedSources,
      savingSources: savedSources,
      totalReserved: totalReserved,
      totalSaved: totalSaved,
      totalProgress: totalReserved + totalSaved,
    );
  }
}
