import 'package:hive/hive.dart';

import '../core/money/money.dart';
import '../models/account.dart';
import '../models/commitment.dart';
import '../models/debt/debt_summary.dart';
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
