import '../models/goal_activity.dart';
import '../models/goal_funding_source.dart';
import 'goal_activity_service.dart';
import 'account_service.dart';

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
}
