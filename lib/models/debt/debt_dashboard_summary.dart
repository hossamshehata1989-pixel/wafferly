import '../../core/money/money.dart';
import '../account.dart';
import '../commitment.dart';
import '../schedule_rule.dart';

/// Aggregated read model for the Debt dashboard.
///
/// This is derived data owned by DebtQueryService. Presentation layers must
/// consume these values instead of independently aggregating DebtSummary.
final class DebtDashboardSummary {
  final Money totalOutstanding;
  final Money totalThisMonth;
  final DebtStateTotal overdue;
  final DebtStateTotal dueSoon;
  final DebtStateTotal upcoming;
  final List<DebtCategorySummary> categories;

  const DebtDashboardSummary({
    required this.totalOutstanding,
    required this.totalThisMonth,
    required this.overdue,
    required this.dueSoon,
    required this.upcoming,
    required this.categories,
  });
}

final class DebtStateTotal {
  final int count;
  final Money amount;

  const DebtStateTotal({
    required this.count,
    required this.amount,
  });
}

enum DebtRisk {
  overdue,
  critical,
  dueSoon,
  upcoming,
  inactive,
}

final class DebtCategorySummary {
  final String title;
  final String type;
  final List<Account> accounts;
  final Money outstanding;
  final Money thisMonth;
  final DebtRisk risk;
  final bool inactive;

  const DebtCategorySummary({
    required this.title,
    required this.type,
    required this.accounts,
    required this.outstanding,
    required this.thisMonth,
    required this.risk,
    required this.inactive,
  });
}
