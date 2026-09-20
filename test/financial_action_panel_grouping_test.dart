import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/core/money/money.dart';
import 'package:wafferly/features/financial_action_center/models/financial_action_day_group.dart';
import 'package:wafferly/features/financial_action_center/models/financial_action_group.dart';
import 'package:wafferly/features/financial_action_center/models/financial_action_projection_group.dart';
import 'package:wafferly/features/financial_action_center/screens/financial_action_panel.dart';
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
import 'package:wafferly/features/financial_action_center/models/financial_action_filter.dart';

void main() {
  testWidgets('renders one grouped action for multiple occurrences', (tester) async {
    final contexts = List.generate(3, (index) {
      final dueDate = DateTime(2026, 9, 12 + index);
      final rule = ScheduleRule(
        id: 'rule-loan',
        frequency: Frequency.daily,
        startDate: dueDate,
        nextDueDate: dueDate,
      );
      final commitment = Commitment(
        id: 'loan',
        title: 'Daily Loan Payment',
        type: CommitmentType.liabilityPayment,
        status: CommitmentStatus.active,
        amount: Money.parse('100'),
        amountMode: CommitmentAmountMode.fixed,
        scheduleRuleId: rule.id,
        sourceAccountId: 'wallet',
        liabilityAccountId: 'loan',
      );
      final occurrence = ScheduleOccurrence(
        id: 'occ-$index',
        scheduleRuleId: rule.id,
        dueDate: dueDate,
      );
      final action = ScheduledAction(
        id: occurrence.id,
        kind: ScheduledActionKind.liabilityPayment,
        state: ScheduledActionState.overdue,
        title: commitment.title,
        subtitle: 'Scheduled Commitment',
        amount: 100,
        dueDate: dueDate,
        sourceAccountId: 'wallet',
        commitmentId: commitment.id,
        liabilityAccountId: 'loan',
      );
      return ScheduledActionExecutionContext(
        action: action,
        commitment: commitment,
        scheduleRule: rule,
        occurrence: occurrence,
      );
    });

    final projection = FinancialActionProjectionGroup(
      key: 'commitment:loan:liabilityPayment',
      title: 'Daily Loan Payment',
      kind: ScheduledActionKind.liabilityPayment,
      contexts: contexts,
      earliestDueDate: contexts.first.occurrence.dueDate,
      overdueCount: 3,
      todayCount: 0,
      tomorrowCount: 0,
      upcomingCount: 0,
    );

    final group = FinancialActionDayGroup(
      group: FinancialActionGroup.overdue,
      actions: [projection],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FinancialActionPanel(
            groups: [group],
            onExecute: (_) async => true,
            onSkip: () {},
            isLoading: false,
            selectedFilter: FinancialActionFilter.all,
            onFilterChanged: (_) {},
            filterCounts: const {
              FinancialActionFilter.all: 1,
            },
          ),
        ),
      ),
    );

    expect(find.text('Daily Loan Payment'), findsOneWidget);
    expect(find.text('3 scheduled payments'), findsOneWidget);
    expect(find.text('3 overdue'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
  });
}
