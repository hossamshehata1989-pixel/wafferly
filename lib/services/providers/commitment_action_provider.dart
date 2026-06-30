import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../models/commitment.dart';
import '../../models/schedule_rule.dart';
import '../../models/scheduled_action.dart';

import '../../models/enums/scheduled_action_kind.dart';

import '../schedule_evaluator.dart';

import 'financial_action_provider.dart';
import '../../models/enums/commitment_type.dart';
import '../../models/scheduled_action_execution_context.dart';

class CommitmentActionProvider implements FinancialActionProvider {
  final ScheduleEvaluator evaluator;

  const CommitmentActionProvider({required this.evaluator});

  @override
  Future<List<ScheduledActionExecutionContext>> getActions({
    required DateTime today,
  }) async {
    final commitmentBox = Hive.box<Commitment>('commitments');
    final scheduleBox = Hive.box<ScheduleRule>('schedule_rules');

    debugPrint('============================');
    debugPrint('Commitments: ${commitmentBox.length}');
    debugPrint('Schedule Rules: ${scheduleBox.length}');
    debugPrint('============================');

    final List<ScheduledActionExecutionContext> actions = [];
    for (final commitment in commitmentBox.values) {
      debugPrint('Checking: ${commitment.title}');
      if (commitment.isArchived) {
        debugPrint('${commitment.title} -> Archived');
        continue;
      }

      final rule = scheduleBox.get(commitment.scheduleRuleId);

      if (rule == null) {
        debugPrint('${commitment.title} -> Missing Schedule Rule');
        continue;
      }

      final state = evaluator.evaluate(rule: rule, today: today);

      final action = ScheduledAction(
        id: commitment.id,
        kind: _mapKind(commitment.type),
        state: state,
        title: commitment.title,
        subtitle: 'Scheduled Commitment',
        amount: commitment.amount,
        dueDate: rule.nextDueDate,
        sourceAccountId: commitment.sourceAccountId,
        destinationAccountId: commitment.destinationAccountId,
        commitmentId: commitment.id,
        liabilityAccountId: commitment.liabilityAccountId,
      );

      debugPrint('${commitment.title} -> Action Created');

      actions.add(
        ScheduledActionExecutionContext(
          action: action,
          commitment: commitment,
          scheduleRule: rule,
        ),
      );
    }

    return actions;
  }

  ScheduledActionKind _mapKind(CommitmentType type) {
    switch (type) {
      case CommitmentType.income:
        return ScheduledActionKind.income;

      case CommitmentType.expense:
        return ScheduledActionKind.expense;

      case CommitmentType.transfer:
        return ScheduledActionKind.transfer;

      case CommitmentType.liabilityPayment:
        return ScheduledActionKind.liabilityPayment;
    }
  }
}
