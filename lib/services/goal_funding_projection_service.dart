// lib/services/goal_funding_projection_service.dart

import '../models/goal_funding_source.dart';
import '../models/goal_funding_projection.dart';
import 'allocation_service.dart';
import 'account_service.dart';
import '../models/goal_activity.dart'; // ✅ GoalActivityType from domain model
import 'goal_activity_service.dart';
import '../models/enums/allocation_type.dart';

class GoalFundingProjectionService {
  final AllocationService _allocationService = AllocationService();
  final AccountService _accountService = AccountService();
  final GoalActivityService _activityService = GoalActivityService();

  /// Get current funding sources from active Allocations (reserved money)
  List<GoalFundingSource> getFundingSources(String goalId) {
    // Get all allocations for this goal of type 'goal'
    final allocations = _allocationService
        .getAll()
        .where((a) => a.type == AllocationType.goal && a.referenceId == goalId)
        .toList();

    // Group by accountId and sum amounts
    final Map<String, double> totals = {};
    for (final alloc in allocations) {
      final account = _accountService.getAccountById(alloc.accountId);

      // Exclude archived source accounts from projections
      if (account == null || account.isArchived) {
        continue;
      }

      totals[alloc.accountId] = (totals[alloc.accountId] ?? 0) + alloc.amount;
    }

    // Convert to FundingSource list
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

  /// Get saved sources from transfer_to_saving activities (history)
  List<GoalFundingSource> getSavedSources(String goalId) {
    final activities = _activityService.getGoalActivities(goalId);

    final Map<String, double> totals = {};
    for (final activity in activities) {
      if (activity.type == GoalActivityType.transferToSaving) {
        final accountId = activity.destinationAccountId;
        if (accountId != null) {
          // Do NOT filter archived accounts — historical data must remain
          totals[accountId] = (totals[accountId] ?? 0) + activity.amount;
        }
      }
    }

    return totals.entries.map((entry) {
      final account = _accountService.getAccountById(entry.key);
      return GoalFundingSource(
        accountId: entry.key,
        accountName:
            account?.name ??
            'Unknown', // Fallback for archived/deleted accounts
        amount: entry.value,
        isSaving: true,
      );
    }).toList();
  }

  /// Get full projection: current reserved state (from Allocations) + saved state (from history)
  GoalFundingProjection getProjection(String goalId) {
    final reservedSources = getFundingSources(goalId);
    final savedSources = getSavedSources(goalId);

    final totalReserved = reservedSources.fold<double>(
      0,
      (sum, s) => sum + s.amount,
    );
    final totalSaved = savedSources.fold<double>(0, (sum, s) => sum + s.amount);

    return GoalFundingProjection(
      reservedSources: reservedSources,
      savingSources: savedSources, // Now contains real data
      totalReserved: totalReserved,
      totalSaved: totalSaved,
      totalProgress: totalReserved + totalSaved,
    );
  }
}
