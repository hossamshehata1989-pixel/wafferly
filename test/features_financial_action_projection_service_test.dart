import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/core/money/money.dart';
import 'package:wafferly/features/financial_action_center/services/financial_action_projection_service.dart';
import 'package:wafferly/models/commitment.dart';
import 'package:wafferly/models/enums/commitment_amount_mode.dart';
import 'package:wafferly/models/enums/commitment_status.dart';
import 'package:wafferly/models/enums/commitment_type.dart';
import 'package:wafferly/models/enums/frequency.dart';
import 'package:wafferly/models/enums/scheduled_action_kind.dart';
import 'package:wafferly/models/enums/scheduled_action_state.dart';
import 'package:wafferly/models/schedule_occurrence.dart';
import 'package:wafferly/models/schedule_rule.dart';
import 'package:wafferly/models/scheduled_action.dart';
import 'package:wafferly/models/scheduled_action_execution_context.dart';

void main() {
  final referenceDate = DateTime(2026, 9, 20);

  ScheduledActionExecutionContext context({
    required String occurrenceId,
    required String commitmentId,
    required DateTime dueDate,
    double amount = 100,
    String title = 'Daily Loan Payment',
    ScheduledActionKind kind = ScheduledActionKind.liabilityPayment,
  }) {
    final rule = ScheduleRule(
      id: 'rule-$commitmentId',
      frequency: Frequency.daily,
      startDate: dueDate,
      nextDueDate: dueDate,
    );
    final commitment = Commitment(
      id: commitmentId,
      title: title,
      type: CommitmentType.liabilityPayment,
      status: CommitmentStatus.active,
      amount: Money.fromDouble(amount),
      amountMode: CommitmentAmountMode.fixed,
      scheduleRuleId: rule.id,
      sourceAccountId: 'wallet',
      liabilityAccountId: 'loan',
    );
    final occurrence = ScheduleOccurrence(
      id: occurrenceId,
      scheduleRuleId: rule.id,
      dueDate: dueDate,
    );
    final action = ScheduledAction(
      id: occurrenceId,
      kind: kind,
      state: ScheduledActionState.overdue,
      title: title,
      subtitle: 'Scheduled Commitment',
      amount: amount,
      dueDate: dueDate,
      sourceAccountId: 'wallet',
      commitmentId: commitmentId,
      liabilityAccountId: 'loan',
    );

    return ScheduledActionExecutionContext(
      action: action,
      commitment: commitment,
      scheduleRule: rule,
      occurrence: occurrence,
    );
  }

  test('groups multiple occurrences of the same commitment', () {
    final actions = [
      context(
        occurrenceId: 'o1',
        commitmentId: 'loan-1',
        dueDate: DateTime(2026, 9, 12),
      ),
      context(
        occurrenceId: 'o2',
        commitmentId: 'loan-1',
        dueDate: DateTime(2026, 9, 13),
      ),
      context(
        occurrenceId: 'o3',
        commitmentId: 'loan-1',
        dueDate: DateTime(2026, 9, 20),
      ),
    ];

    final groups = const FinancialActionProjectionService().project(
      actions,
      referenceDate: referenceDate,
    );

    expect(groups, hasLength(1));
    expect(groups.single.count, 3);
    expect(groups.single.totalAmount, 300);
    expect(groups.single.overdueCount, 2);
    expect(groups.single.todayCount, 1);
    expect(groups.single.isGrouped, isTrue);
    expect(groups.single.summary, '2 overdue • 1 due today');
  });

  test('keeps different commitments as separate projected actions', () {
    final actions = [
      context(
        occurrenceId: 'loan-1',
        commitmentId: 'loan',
        dueDate: DateTime(2026, 9, 20),
      ),
      context(
        occurrenceId: 'loan-2',
        commitmentId: 'loan',
        dueDate: DateTime(2026, 9, 21),
      ),
      context(
        occurrenceId: 'electricity-1',
        commitmentId: 'electricity',
        dueDate: DateTime(2026, 9, 20),
        amount: 350,
        title: 'Electricity Bill',
        kind: ScheduledActionKind.expense,
      ),
    ];

    final groups = const FinancialActionProjectionService().project(
      actions,
      referenceDate: referenceDate,
    );

    expect(groups, hasLength(2));
    expect(
      groups.map((group) => group.title),
      containsAll(<String>['Daily Loan Payment', 'Electricity Bill']),
    );
  });

  test('keeps a non-commitment action as an individual projection', () {
    final action = context(
      occurrenceId: 'action-1',
      commitmentId: '',
      dueDate: referenceDate,
    );

    final groups = const FinancialActionProjectionService().project(
      [action],
      referenceDate: referenceDate,
    );

    expect(groups, hasLength(1));
    expect(groups.single.count, 1);
    expect(groups.single.isGrouped, isFalse);
  });
}
