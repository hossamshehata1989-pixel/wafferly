import 'package:hive/hive.dart';

import '../core/money/money.dart';
import '../models/account.dart';
import '../models/commitment.dart';
import '../models/debt/debt_summary.dart';
import '../models/debt/debt_dashboard_summary.dart';
import '../models/enums/account_enums.dart';
import '../models/enums/commitment_status.dart';
import '../models/enums/commitment_type.dart';
import '../models/enums/schedule_occurrence_status.dart';
import '../models/schedule_occurrence.dart';
import '../models/schedule_rule.dart';
import 'balance_service.dart';
import 'schedule_evaluator.dart';

/// Read-only debt query layer.
///
/// Liability Accounts remain the source of truth for current financial
/// position. Commitments, ScheduleRules, and Occurrences provide future
/// payment expectations and settlement state.
final class DebtQueryService {
  final BalanceService balanceService;
  final Box<Account> accountBox;
  final Box<Commitment> commitmentBox;
  final Box<ScheduleRule> scheduleRuleBox;
  final Box<ScheduleOccurrence> occurrenceBox;
  final ScheduleEvaluator evaluator;

  const DebtQueryService({
    required this.balanceService,
    required this.accountBox,
    required this.commitmentBox,
    required this.scheduleRuleBox,
    required this.occurrenceBox,
    this.evaluator = const ScheduleEvaluator(),
  });

  List<DebtSummary> getDebtSummaries({required DateTime today}) {
    final liabilities = accountBox.values.where(
      (account) =>
          !account.isArchived && account.nature == AccountNature.liability,
    );

    return liabilities.map((account) {
      final next = _findNextPayment(account.id);
      final balance = balanceService.getBalance(account.id).abs();

      if (next == null) {
        return DebtSummary(
          liabilityAccount: account,
          outstanding: Money.fromDouble(balance),
        );
      }

      final rule = scheduleRuleBox.get(next.scheduleRuleId);
      if (rule == null) {
        return DebtSummary(
          liabilityAccount: account,
          outstanding: Money.fromDouble(balance),
          nextPayment: next,
        );
      }

      final occurrence = occurrenceBox.get(
        ScheduleOccurrence.idFor(
          scheduleRuleId: rule.id,
          dueDate: rule.nextDueDate,
        ),
      );

      return DebtSummary(
        liabilityAccount: account,
        outstanding: Money.fromDouble(balance),
        nextPayment: next,
        scheduleRule: rule,
        occurrence: occurrence,
        paymentState: evaluator.evaluate(rule: rule, today: today),
      );
    }).toList();
  }


  DebtDashboardSummary getDebtDashboardSummary({required DateTime today}) {
    final summaries = getDebtSummaries(today: today);

    final totalOutstanding = summaries.fold<Money>(
      Money.zero,
      (sum, item) => sum + item.outstanding,
    );

    final totalThisMonth = _calculateThisMonthTotal(summaries, today);

    final overdue = _calculateStateTotal(
      summaries,
      today,
      DebtRisk.overdue,
    );
    final dueSoon = _calculateStateTotal(
      summaries,
      today,
      DebtRisk.dueSoon,
    );
    final upcoming = _calculateStateTotal(
      summaries,
      today,
      DebtRisk.upcoming,
    );

    return DebtDashboardSummary(
      totalOutstanding: totalOutstanding,
      totalThisMonth: totalThisMonth,
      overdue: overdue,
      dueSoon: dueSoon,
      upcoming: upcoming,
      categories: _buildCategories(summaries, today),
    );
  }

  List<DebtCategorySummary> _buildCategories(
    List<DebtSummary> summaries,
    DateTime today,
  ) {
    const definitions = <({String title, String type})>[
      (title: 'Credit Cards', type: 'creditCard'),
      (title: 'Loans', type: 'loan'),
      (title: 'Installment Companies', type: 'installment'),
      (title: 'Borrowed Money', type: 'debt'),
    ];

    return [
      for (final definition in definitions)
        _buildCategory(
          definition.title,
          definition.type,
          summaries,
          today,
        ),
      DebtCategorySummary(
        title: 'Temporary Debt',
        type: 'temporaryDebt',
        accounts: <Account>[],
        outstanding: Money.zero,
        thisMonth: Money.zero,
        risk: DebtRisk.inactive,
        inactive: true,
      ),
      DebtCategorySummary(
        title: 'Rotating Savings (Collection)',
        type: 'rotatingSavings',
        accounts: <Account>[],
        outstanding: Money.zero,
        thisMonth: Money.zero,
        risk: DebtRisk.inactive,
        inactive: true,
      ),
    ];
  }

  DebtCategorySummary _buildCategory(
    String title,
    String type,
    List<DebtSummary> summaries,
    DateTime today,
  ) {
    final matches = summaries
        .where((summary) => summary.liabilityAccount.type == type)
        .toList();

    final outstanding = matches.fold<Money>(
      Money.zero,
      (sum, item) => sum + item.outstanding,
    );

    final accountIds = <String>{};
    var thisMonth = Money.zero;
    for (final summary in matches) {
      if (accountIds.add(summary.liabilityAccount.id)) {
        thisMonth += _thisMonthForAccount(
          summary.liabilityAccount.id,
          today,
        );
      }
    }

    return DebtCategorySummary(
      title: title,
      type: type,
      accounts: matches.map((item) => item.liabilityAccount).toList(),
      outstanding: outstanding,
      thisMonth: thisMonth,
      risk: _riskForSummaries(matches, today),
      inactive: matches.isEmpty,
    );
  }

  DebtRisk _riskForSummaries(
    List<DebtSummary> summaries,
    DateTime today,
  ) {
    var risk = DebtRisk.upcoming;
    final current = DateTime(today.year, today.month, today.day);

    for (final summary in summaries) {
      final rule = summary.scheduleRule;
      if (summary.nextPayment == null || rule == null) continue;

      final due = DateTime(
        rule.nextDueDate.year,
        rule.nextDueDate.month,
        rule.nextDueDate.day,
      );
      final days = due.difference(current).inDays;

      final candidate = days < 0
          ? DebtRisk.overdue
          : days == 0
              ? DebtRisk.critical
              : days <= 7
                  ? DebtRisk.dueSoon
                  : DebtRisk.upcoming;

      if (candidate.index < risk.index) {
        risk = candidate;
      }
    }

    return risk;
  }

  Money _calculateThisMonthTotal(
    List<DebtSummary> summaries,
    DateTime today,
  ) {
    final seen = <String>{};
    var total = Money.zero;

    for (final summary in summaries) {
      final id = summary.liabilityAccount.id;
      if (seen.add(id)) {
        total += _thisMonthForAccount(id, today);
      }
    }

    return total;
  }

  Money _thisMonthForAccount(
    String accountId,
    DateTime today,
  ) {
    var total = Money.zero;

    for (final commitment in commitmentBox.values) {
      if (commitment.isArchived ||
          commitment.status != CommitmentStatus.active ||
          commitment.type != CommitmentType.liabilityPayment ||
          commitment.liabilityAccountId != accountId) {
        continue;
      }

      final rule = scheduleRuleBox.get(commitment.scheduleRuleId);
      if (rule == null) continue;

      final dueDate = rule.nextDueDate;
      if (dueDate.year != today.year || dueDate.month != today.month) {
        continue;
      }

      final occurrence = occurrenceBox.get(
        ScheduleOccurrence.idFor(
          scheduleRuleId: rule.id,
          dueDate: dueDate,
        ),
      );

      if (occurrence?.status == ScheduleOccurrenceStatus.completed) {
        continue;
      }

      total += commitment.amount;
    }

    return total;
  }

  DebtStateTotal _calculateStateTotal(
    List<DebtSummary> summaries,
    DateTime today,
    DebtRisk state,
  ) {
    final current = DateTime(today.year, today.month, today.day);
    var count = 0;
    var amount = Money.zero;

    for (final summary in summaries) {
      final payment = summary.nextPayment;
      final rule = summary.scheduleRule;
      if (payment == null || rule == null) continue;

      final due = DateTime(
        rule.nextDueDate.year,
        rule.nextDueDate.month,
        rule.nextDueDate.day,
      );
      final days = due.difference(current).inDays;

      final matches = switch (state) {
        DebtRisk.overdue => days < 0,
        DebtRisk.dueSoon => days >= 0 && days <= 7,
        DebtRisk.upcoming => days > 7,
        _ => false,
      };

      if (!matches) continue;

      count++;
      amount += payment.amount;
    }

    return DebtStateTotal(count: count, amount: amount);
  }

  DebtSummary? getDebtSummary(
    String liabilityAccountId, {
    required DateTime today,
  }) {
    for (final summary in getDebtSummaries(today: today)) {
      if (summary.liabilityAccount.id == liabilityAccountId) {
        return summary;
      }
    }
    return null;
  }

  Commitment? _findNextPayment(String liabilityAccountId) {
    final candidates = commitmentBox.values.where(
      (commitment) =>
          !commitment.isArchived &&
          commitment.status == CommitmentStatus.active &&
          commitment.type == CommitmentType.liabilityPayment &&
          commitment.liabilityAccountId == liabilityAccountId,
    );

    Commitment? result;
    ScheduleRule? resultRule;

    for (final commitment in candidates) {
      final rule = scheduleRuleBox.get(commitment.scheduleRuleId);
      if (rule == null) continue;
      if (rule.endDate != null && rule.nextDueDate.isAfter(rule.endDate!)) {
        continue;
      }

      // A one-time occurrence that has already settled is no longer a
      // pending future payment. Do not expose it as the next payment even
      // if the one-time rule intentionally keeps its cursor unchanged.
      final occurrence = occurrenceBox.get(
        ScheduleOccurrence.idFor(
          scheduleRuleId: rule.id,
          dueDate: rule.nextDueDate,
        ),
      );
      if (occurrence?.status == ScheduleOccurrenceStatus.completed) {
        continue;
      }

      if (resultRule == null || rule.nextDueDate.isBefore(resultRule.nextDueDate)) {
        result = commitment;
        resultRule = rule;
      }
    }

    return result;
  }
}
