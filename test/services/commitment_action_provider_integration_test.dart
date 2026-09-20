import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:wafferly/core/money/money.dart';
import 'package:wafferly/models/commitment.dart';
import 'package:wafferly/models/enums/commitment_amount_mode.dart';
import 'package:wafferly/models/enums/commitment_status.dart';
import 'package:wafferly/models/enums/commitment_type.dart';
import 'package:wafferly/models/enums/frequency.dart';
import 'package:wafferly/models/enums/scheduled_action_kind.dart';
import 'package:wafferly/models/enums/schedule_occurrence_status.dart';
import 'package:wafferly/models/schedule_occurrence.dart';
import 'package:wafferly/models/schedule_rule.dart';
import 'package:wafferly/services/providers/commitment_action_provider.dart';
import 'package:wafferly/services/schedule_evaluator.dart';
import 'package:wafferly/services/schedule_occurrence_service.dart';
import 'package:wafferly/services/schedule_rule_service.dart';

void main() {
  final dueDate = DateTime(2026, 9, 12);

  setUpAll(() async {
  Hive.init('test_commitment_action_provider');
if (!Hive.isAdapterRegistered(91)) {
  Hive.registerAdapter(CommitmentTypeAdapter());
}

if (!Hive.isAdapterRegistered(92)) {
  Hive.registerAdapter(CommitmentStatusAdapter());
}

if (!Hive.isAdapterRegistered(93)) {
  Hive.registerAdapter(CommitmentAmountModeAdapter());
}

if (!Hive.isAdapterRegistered(94)) {
  Hive.registerAdapter(FrequencyAdapter());
}

if (!Hive.isAdapterRegistered(95)) {
  Hive.registerAdapter(ScheduleRuleAdapter());
}
  if (!Hive.isAdapterRegistered(94)) {
    Hive.registerAdapter(FrequencyAdapter());
  }

  if (!Hive.isAdapterRegistered(95)) {
    Hive.registerAdapter(ScheduleRuleAdapter());
  }

  if (!Hive.isAdapterRegistered(96)) {
    Hive.registerAdapter(CommitmentAdapter());
  }

  if (!Hive.isAdapterRegistered(98)) {
    Hive.registerAdapter(ScheduleOccurrenceAdapter());
  }

  if (!Hive.isAdapterRegistered(99)) {
    Hive.registerAdapter(ScheduleOccurrenceStatusAdapter());
  }

  await Hive.openBox<Commitment>('commitments');
  await Hive.openBox<ScheduleRule>('schedule_rules');
  await Hive.openBox<ScheduleOccurrence>('schedule_occurrences');
});

  setUp(() async {
    await Hive.box<Commitment>('commitments').clear();
    await Hive.box<ScheduleRule>('schedule_rules').clear();
    await Hive.box<ScheduleOccurrence>('schedule_occurrences').clear();
  });

  tearDownAll(() async {
    await Hive.deleteBoxFromDisk('commitments');
    await Hive.deleteBoxFromDisk('schedule_rules');
    await Hive.deleteBoxFromDisk('schedule_occurrences');
  });

  test('creates occurrence, maps ScheduledAction, and does not advance nextDueDate',
      () async {
    final rule = ScheduleRule(
      id: 'rule-1',
      frequency: Frequency.daily,
      startDate: dueDate,
      nextDueDate: dueDate,
    );

    final commitment = Commitment(
      id: 'commitment-1',
      title: 'Daily Expense',
      type: CommitmentType.expense,
      status: CommitmentStatus.active,
      amount: Money.parse('125.50'),
      amountMode: CommitmentAmountMode.fixed,
      scheduleRuleId: rule.id,
      sourceAccountId: 'account-source',
      destinationAccountId: 'account-destination',
    );

    await Hive.box<ScheduleRule>('schedule_rules').put(rule.id, rule);
    await Hive.box<Commitment>('commitments').put(commitment.id, commitment);

    final occurrenceService = ScheduleOccurrenceService(
      ruleService: ScheduleRuleService(),
    );
    final provider = CommitmentActionProvider(
      evaluator: const ScheduleEvaluator(),
      occurrenceService: occurrenceService,
    );

    final contexts = await provider.getActions(today: dueDate);

    expect(contexts, hasLength(1));

    final context = contexts.single;
    final occurrence = context.occurrence;
    final action = context.action;

    final expectedOccurrenceId = ScheduleOccurrence.idFor(
      scheduleRuleId: rule.id,
      dueDate: dueDate,
    );

    // Occurrence creation is owned by the provider's occurrence boundary.
    expect(occurrence.id, expectedOccurrenceId);
    expect(occurrence.scheduleRuleId, rule.id);
    expect(occurrence.dueDate, dueDate);
    expect(occurrence.status, ScheduleOccurrenceStatus.pending);
    expect(
      Hive.box<ScheduleOccurrence>('schedule_occurrences').get(expectedOccurrenceId),
      isNotNull,
    );

    // ScheduledAction is mapped to the occurrence slot, while financial
    // amount crosses the explicit Money -> double compatibility boundary.
    expect(action.id, expectedOccurrenceId);
    expect(action.kind, ScheduledActionKind.expense);
    expect(action.title, commitment.title);
    expect(action.amount, 125.50);
    expect(action.dueDate, dueDate);
    expect(action.commitmentId, commitment.id);
    expect(context.commitment.id, commitment.id);
    expect(context.scheduleRule.id, rule.id);

    // getActions() is a read/presentation operation: it must not consume the
    // recurrence cursor. Advancement is an explicit post-processing step.
    final storedRule = Hive.box<ScheduleRule>('schedule_rules').get(rule.id)!;
    expect(storedRule.nextDueDate, dueDate);
  });
}
