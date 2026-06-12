import '../models/goal_activity.dart';
import '../models/goal_funding_source.dart';
import 'goal_activity_service.dart';
import 'account_service.dart';
import '../models/goal_funding_projection.dart';

class GoalFundingProjectionService {
  final GoalActivityService _activityService = GoalActivityService();

  final AccountService _accountService = AccountService();

  List<GoalFundingSource> getFundingSources(String goalId) {
    final activities = _activityService.getGoalActivities(goalId);

    final Map<String, double> totals = {};

    for (final activity in activities) {
      final accountId = activity.sourceAccountId;

      if (accountId == null) {
        continue;
      }

      if (activity.type == 'reserve') {
        totals[accountId] = (totals[accountId] ?? 0) + activity.amount;
      }

      if (activity.type == 'release') {
        totals[accountId] = (totals[accountId] ?? 0) - activity.amount;
      }
    }

    totals.removeWhere((key, value) => value <= 0);

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

  Future<GoalFundingProjection> getProjection(String goalId) async {
    final fundingSources = getFundingSources(goalId);

    final reservedSources = fundingSources.where((s) => !s.isSaving).toList();

    final savingSources = fundingSources.where((s) => s.isSaving).toList();

    final totalReserved = reservedSources.fold<double>(
      0,
      (sum, source) => sum + source.amount,
    );

    final totalSaved = savingSources.fold<double>(
      0,
      (sum, source) => sum + source.amount,
    );
    print('------------------------');
    print('GOAL PROJECTION');
    print('Reserved: $totalReserved');
    print('Saved: $totalSaved');
    print('Progress: ${totalReserved + totalSaved}');
    print('------------------------');
    return GoalFundingProjection(
      reservedSources: reservedSources,
      savingSources: savingSources,
      totalReserved: totalReserved,
      totalSaved: totalSaved,
      totalProgress: totalReserved + totalSaved,
    );
  }
}
