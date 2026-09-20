import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../models/commitment.dart';
import '../../models/enums/commitment_status.dart';
import '../../models/enums/commitment_type.dart';
import '../../models/enums/scheduled_action_kind.dart';
import '../../models/schedule_rule.dart';
import '../../models/scheduled_action.dart';
import '../../models/scheduled_action_execution_context.dart';

import '../schedule_evaluator.dart';
import '../schedule_occurrence_service.dart';

import 'financial_action_provider.dart';

class CommitmentActionProvider implements FinancialActionProvider {
  final ScheduleEvaluator evaluator;
  final ScheduleOccurrenceService occurrenceService;

  const CommitmentActionProvider({
    required this.evaluator,
    required this.occurrenceService,
  });

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

      if (commitment.status != CommitmentStatus.active) {
        debugPrint(
          '${commitment.title} -> Inactive (${commitment.status.name})',
        );
        continue;
      }

      if (commitment.isArchived) {
        debugPrint('${commitment.title} -> Archived');
        continue;
      }

      final rule = scheduleBox.get(commitment.scheduleRuleId);
      if (rule == null) {
        debugPrint('${commitment.title} -> Missing Schedule Rule');
        continue;
      }

      final occurrences = await occurrenceService
          .getOrCreateOccurrencesThroughDate(
        rule,
        today,
      );

      for (final occurrence in occurrences) {
        if (rule.frequency.name == 'oneTime' &&
            occurrence.status.name == 'completed') {
          debugPrint(
            '${commitment.title} -> Occurrence ${occurrence.id} already completed',
          );
          continue;
        }

        final state = evaluator.evaluateDueDate(
          dueDate: occurrence.dueDate,
          today: today,
        );

        final action = ScheduledAction(
          id: occurrence.id,
          kind: _mapKind(commitment.type),
          state: state,
          title: commitment.title,
          subtitle: 'Scheduled Commitment',
          amount: commitment.amount.toDouble(),
          dueDate: occurrence.dueDate,
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
            occurrence: occurrence,
          ),
        );
      }
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
