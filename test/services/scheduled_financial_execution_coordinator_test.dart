import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:wafferly/core/money/money.dart';
import 'package:wafferly/financial_engine/execution/financial_execution_summary.dart';
import 'package:wafferly/financial_engine/results/operation_result.dart';
import 'package:wafferly/models/commitment.dart';
import 'package:wafferly/models/enums/commitment_amount_mode.dart';
import 'package:wafferly/models/enums/commitment_status.dart';
import 'package:wafferly/models/enums/commitment_type.dart';
import 'package:wafferly/models/enums/frequency.dart';
import 'package:wafferly/models/enums/schedule_occurrence_status.dart';
import 'package:wafferly/models/enums/scheduled_action_kind.dart';
import 'package:wafferly/models/enums/scheduled_action_state.dart';
import 'package:wafferly/models/schedule_occurrence.dart';
import 'package:wafferly/models/schedule_rule.dart';
import 'package:wafferly/models/scheduled_action.dart';
import 'package:wafferly/models/scheduled_action_execution_context.dart';
import 'package:wafferly/services/schedule_occurrence_service.dart';
import 'package:wafferly/services/schedule_rule_service.dart';
import 'package:wafferly/services/scheduled_execution_journal.dart';
import 'package:wafferly/services/scheduled_financial_execution_coordinator.dart';

class _RuleService extends ScheduleRuleService {
  final Map<String, ScheduleRule> rules = {};
  bool failUpdate = false;

  @override
  ScheduleRule? getRule(String id) => rules[id];

  @override
  Future<void> updateRule(ScheduleRule rule) async {
    if (failUpdate) throw StateError('rule update failed');
    rules[rule.id] = rule;
  }
}

class _OccurrenceService extends ScheduleOccurrenceService {
  final bool Function() failComplete;
  final bool Function() failAdvance;

  _OccurrenceService({
    required super.ruleService,
    required this.failComplete,
    required this.failAdvance,
  });

  @override
  Future<ScheduleOccurrence> completeOccurrence(
    ScheduleOccurrence occurrence,
  ) async {
    if (failComplete()) throw StateError('occurrence completion failed');
    return super.completeOccurrence(occurrence);
  }

  @override
  Future<ScheduleRule> advanceRuleAfterOccurrence(
    ScheduleRule rule,
    ScheduleOccurrence occurrence,
  ) async {
    if (failAdvance()) throw StateError('rule advancement failed');
    return super.advanceRuleAfterOccurrence(rule, occurrence);
  }
}

void main() {
  setUpAll(() async {
    Hive.init('test_scheduled_financial_execution');
    Hive.registerAdapter(ScheduleOccurrenceStatusAdapter());
    Hive.registerAdapter(ScheduleOccurrenceAdapter());
    await Hive.openBox<ScheduleOccurrence>('schedule_occurrences');
    await Hive.openBox<Map>(ScheduledExecutionJournal.boxName);
  });

  tearDown(() async {
    await Hive.box<ScheduleOccurrence>('schedule_occurrences').clear();
    await Hive.box<Map>(ScheduledExecutionJournal.boxName).clear();
  });

  tearDownAll(() async {
    await Hive.deleteBoxFromDisk('schedule_occurrences');
    await Hive.deleteBoxFromDisk(ScheduledExecutionJournal.boxName);
  });

  final dueDate = DateTime(2026, 9, 25);

  ScheduledActionExecutionContext contextFor(ScheduleRule rule) {
    final occurrence = ScheduleOccurrence(
      id: ScheduleOccurrence.idFor(
        scheduleRuleId: rule.id,
        dueDate: rule.nextDueDate,
      ),
      scheduleRuleId: rule.id,
      dueDate: rule.nextDueDate,
    );

    final commitment = Commitment(
      id: 'commitment-1',
      title: 'Test commitment',
      type: CommitmentType.liabilityPayment,
      status: CommitmentStatus.active,
      amount: Money.fromDouble(100),
      amountMode: CommitmentAmountMode.fixed,
      scheduleRuleId: rule.id,
      sourceAccountId: 'wallet',
      liabilityAccountId: 'loan',
    );

    final action = ScheduledAction(
      id: occurrence.id,
      kind: ScheduledActionKind.liabilityPayment,
      state: ScheduledActionState.due,
      title: 'Test payment',
      subtitle: 'Test',
      amount: 100,
      dueDate: rule.nextDueDate,
      commitmentId: commitment.id,
      sourceAccountId: 'wallet',
      liabilityAccountId: 'loan',
    );

    return ScheduledActionExecutionContext(
      action: action,
      commitment: commitment,
      scheduleRule: rule,
      occurrence: occurrence,
    );
  }

  ScheduleRule rule() => ScheduleRule(
        id: 'rule-1',
        frequency: Frequency.daily,
        startDate: dueDate,
        nextDueDate: dueDate,
      );

  OperationSucceeded success() => const OperationSucceeded(
        summary: FinancialExecutionSummary(
          createdTransactionIds: ['tx-1'],
          balanceChanges: {},
          createdMutationIds: [],
        ),
      );

  test('financial success completes occurrence and advances rule', () async {
    final rules = _RuleService();
    rules.rules['rule-1'] = rule();
    final occurrences = _OccurrenceService(
      ruleService: rules,
      failComplete: () => false,
      failAdvance: () => false,
    );
    final coordinator = ScheduledFinancialExecutionCoordinator(
      occurrenceService: occurrences,
      journal: ScheduledExecutionJournal(
        Hive.box<Map>(ScheduledExecutionJournal.boxName),
      ),
    );

    var financialCalls = 0;
    final context = contextFor(rule());
    final result = await coordinator.execute(
      action: context,
      idempotencyKey: 'scheduled:${context.occurrence.id}',
      executeFinancialOperation: () async {
        financialCalls++;
        return success();
      },
    );

    expect(result, isTrue);
    expect(financialCalls, 1);
    expect(
      Hive.box<ScheduleOccurrence>('schedule_occurrences')
          .get(context.occurrence.id)!
          .status,
      ScheduleOccurrenceStatus.completed,
    );
    expect(rules.rules['rule-1']!.nextDueDate, DateTime(2026, 9, 26));
    expect(
      Hive.box<Map>(ScheduledExecutionJournal.boxName)
          .get(context.occurrence.id)!['state'],
      ScheduledExecutionJournal.stateCompleted,
    );
  });

  test('financial failure is retryable and does not advance scheduling', () async {
    final rules = _RuleService();
    rules.rules['rule-1'] = rule();
    final occurrences = _OccurrenceService(
      ruleService: rules,
      failComplete: () => false,
      failAdvance: () => false,
    );
    final coordinator = ScheduledFinancialExecutionCoordinator(
      occurrenceService: occurrences,
      journal: ScheduledExecutionJournal(
        Hive.box<Map>(ScheduledExecutionJournal.boxName),
      ),
    );

    var financialCalls = 0;
    final context = contextFor(rule());
    final result = await coordinator.execute(
      action: context,
      idempotencyKey: 'scheduled:${context.occurrence.id}',
      executeFinancialOperation: () async {
        financialCalls++;
        return const OperationFailed(error: 'financial failed');
      },
    );

    expect(result, isFalse);
    expect(financialCalls, 1);
    expect(
      Hive.box<ScheduleOccurrence>('schedule_occurrences').get(
        context.occurrence.id,
      ),
      isNull,
    );
    expect(rules.rules['rule-1']!.nextDueDate, dueDate);
    expect(
      Hive.box<Map>(ScheduledExecutionJournal.boxName)
          .get(context.occurrence.id)!['state'],
      ScheduledExecutionJournal.stateFailed,
    );
  });

  test('completion failure leaves durable financial success for recovery', () async {
    final rules = _RuleService();
    rules.rules['rule-1'] = rule();
    final occurrences = _OccurrenceService(
      ruleService: rules,
      failComplete: () => true,
      failAdvance: () => false,
    );
    final coordinator = ScheduledFinancialExecutionCoordinator(
      occurrenceService: occurrences,
      journal: ScheduledExecutionJournal(
        Hive.box<Map>(ScheduledExecutionJournal.boxName),
      ),
    );

    final context = contextFor(rule());
    var financialCalls = 0;
    final result = await coordinator.execute(
      action: context,
      idempotencyKey: 'scheduled:${context.occurrence.id}',
      executeFinancialOperation: () async {
        financialCalls++;
        return success();
      },
    );

    expect(result, isFalse);
    expect(financialCalls, 1);
    expect(
      Hive.box<Map>(ScheduledExecutionJournal.boxName)
          .get(context.occurrence.id)!['state'],
      ScheduledExecutionJournal.stateFinancialSucceeded,
    );
    expect(
      Hive.box<ScheduleOccurrence>('schedule_occurrences')
          .get(context.occurrence.id),
      isNull,
    );
  });

  test('retry after completion failure does not execute financial operation twice', () async {
    final rules = _RuleService();
    rules.rules['rule-1'] = rule();
    var fail = true;
    final occurrences = _OccurrenceService(
      ruleService: rules,
      failComplete: () => fail,
      failAdvance: () => false,
    );
    final coordinator = ScheduledFinancialExecutionCoordinator(
      occurrenceService: occurrences,
      journal: ScheduledExecutionJournal(
        Hive.box<Map>(ScheduledExecutionJournal.boxName),
      ),
    );

    final context = contextFor(rule());
    var financialCalls = 0;
    Future<OperationResult> executeFinancial() async {
      financialCalls++;
      return success();
    }

    expect(
      await coordinator.execute(
        action: context,
        idempotencyKey: 'scheduled:${context.occurrence.id}',
        executeFinancialOperation: executeFinancial,
      ),
      isFalse,
    );

    fail = false;
    expect(
      await coordinator.execute(
        action: context,
        idempotencyKey: 'scheduled:${context.occurrence.id}',
        executeFinancialOperation: executeFinancial,
      ),
      isTrue,
    );

    expect(financialCalls, 1);
    expect(
      Hive.box<ScheduleOccurrence>('schedule_occurrences')
          .get(context.occurrence.id)!
          .status,
      ScheduleOccurrenceStatus.completed,
    );
    expect(rules.rules['rule-1']!.nextDueDate, DateTime(2026, 9, 26));
  });

  test('advancement failure leaves durable financial success after occurrence completion', () async {
    final rules = _RuleService();
    rules.rules['rule-1'] = rule();
    final occurrences = _OccurrenceService(
      ruleService: rules,
      failComplete: () => false,
      failAdvance: () => true,
    );
    final coordinator = ScheduledFinancialExecutionCoordinator(
      occurrenceService: occurrences,
      journal: ScheduledExecutionJournal(
        Hive.box<Map>(ScheduledExecutionJournal.boxName),
      ),
    );

    final context = contextFor(rule());
    var financialCalls = 0;
    final result = await coordinator.execute(
      action: context,
      idempotencyKey: 'scheduled:${context.occurrence.id}',
      executeFinancialOperation: () async {
        financialCalls++;
        return success();
      },
    );

    expect(result, isFalse);
    expect(financialCalls, 1);
    expect(
      Hive.box<ScheduleOccurrence>('schedule_occurrences')
          .get(context.occurrence.id)!
          .status,
      ScheduleOccurrenceStatus.completed,
    );
    expect(
      Hive.box<Map>(ScheduledExecutionJournal.boxName)
          .get(context.occurrence.id)!['state'],
      ScheduledExecutionJournal.stateFinancialSucceeded,
    );
    expect(rules.rules['rule-1']!.nextDueDate, dueDate);
  });

  test('retry after advancement failure does not execute financial operation twice', () async {
    final rules = _RuleService();
    rules.rules['rule-1'] = rule();
    var fail = true;
    final occurrences = _OccurrenceService(
      ruleService: rules,
      failComplete: () => false,
      failAdvance: () => fail,
    );
    final coordinator = ScheduledFinancialExecutionCoordinator(
      occurrenceService: occurrences,
      journal: ScheduledExecutionJournal(
        Hive.box<Map>(ScheduledExecutionJournal.boxName),
      ),
    );

    final context = contextFor(rule());
    var financialCalls = 0;
    Future<OperationResult> executeFinancial() async {
      financialCalls++;
      return success();
    }

    expect(
      await coordinator.execute(
        action: context,
        idempotencyKey: 'scheduled:${context.occurrence.id}',
        executeFinancialOperation: executeFinancial,
      ),
      isFalse,
    );

    fail = false;
    expect(
      await coordinator.execute(
        action: context,
        idempotencyKey: 'scheduled:${context.occurrence.id}',
        executeFinancialOperation: executeFinancial,
      ),
      isTrue,
    );

    expect(financialCalls, 1);
    expect(rules.rules['rule-1']!.nextDueDate, DateTime(2026, 9, 26));
    expect(
      Hive.box<Map>(ScheduledExecutionJournal.boxName)
          .get(context.occurrence.id)!['state'],
      ScheduledExecutionJournal.stateCompleted,
    );
  });

  test('completed execution is idempotent at the orchestration boundary', () async {
    final rules = _RuleService();
    rules.rules['rule-1'] = rule();
    final occurrences = _OccurrenceService(
      ruleService: rules,
      failComplete: () => false,
      failAdvance: () => false,
    );
    final coordinator = ScheduledFinancialExecutionCoordinator(
      occurrenceService: occurrences,
      journal: ScheduledExecutionJournal(
        Hive.box<Map>(ScheduledExecutionJournal.boxName),
      ),
    );

    final context = contextFor(rule());
    var financialCalls = 0;
    final executeFinancial = () async {
      financialCalls++;
      return success();
    };

    expect(
      await coordinator.execute(
        action: context,
        idempotencyKey: 'scheduled:${context.occurrence.id}',
        executeFinancialOperation: executeFinancial,
      ),
      isTrue,
    );
    expect(
      await coordinator.execute(
        action: context,
        idempotencyKey: 'scheduled:${context.occurrence.id}',
        executeFinancialOperation: executeFinancial,
      ),
      isTrue,
    );

    expect(financialCalls, 1);
  });
}
