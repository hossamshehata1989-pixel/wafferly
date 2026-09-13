import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:hive/hive.dart';

import 'package:wafferly/constants/transaction_constants.dart';

import 'package:wafferly/core/money/money.dart';

import 'package:wafferly/models/account.dart';

import 'package:wafferly/models/commitment.dart';

import 'package:wafferly/models/enums/account_enums.dart';

import 'package:wafferly/models/enums/commitment_amount_mode.dart';

import 'package:wafferly/models/enums/commitment_status.dart';

import 'package:wafferly/models/enums/commitment_type.dart';

import 'package:wafferly/models/enums/frequency.dart';

import 'package:wafferly/models/enums/schedule_occurrence_status.dart';

import 'package:wafferly/models/enums/scheduled_action_state.dart';

import 'package:wafferly/models/schedule_occurrence.dart';

import 'package:wafferly/models/schedule_rule.dart';

import 'package:wafferly/models/transaction.dart';

import 'package:wafferly/services/balance_service.dart';

import 'package:wafferly/services/debt_query_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String hivePath;

  late Box<Account> accountBox;

  late Box<Transaction> txBox;

  late Box<Commitment> commitmentBox;

  late Box<ScheduleRule> scheduleRuleBox;

  late Box<ScheduleOccurrence> occurrenceBox;

  late DebtQueryService service;

  setUpAll(() async {
    hivePath = Directory.systemTemp
        .createTempSync('wafferly_debt_query_test_')
        .path;

    Hive.init(hivePath);

    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(AccountAdapter());
    }

    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(AccountNatureAdapter());
    }

    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(AccountGroupAdapter());
    }

    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(TransactionAdapter());
    }

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

    if (!Hive.isAdapterRegistered(96)) {
      Hive.registerAdapter(CommitmentAdapter());
    }

    if (!Hive.isAdapterRegistered(98)) {
      Hive.registerAdapter(ScheduleOccurrenceAdapter());
    }

    if (!Hive.isAdapterRegistered(99)) {
      Hive.registerAdapter(ScheduleOccurrenceStatusAdapter());
    }

    accountBox = await Hive.openBox<Account>('accounts');
    txBox = await Hive.openBox<Transaction>('transactions');
    commitmentBox = await Hive.openBox<Commitment>('commitments');
    scheduleRuleBox = await Hive.openBox<ScheduleRule>('schedule_rules');
    occurrenceBox =
        await Hive.openBox<ScheduleOccurrence>('schedule_occurrences');

    service = DebtQueryService(
      balanceService: BalanceService(),
      accountBox: accountBox,
      commitmentBox: commitmentBox,
      scheduleRuleBox: scheduleRuleBox,
      occurrenceBox: occurrenceBox,
    );
  });

  setUp(() async {
    await accountBox.clear();
    await txBox.clear();
    await commitmentBox.clear();
    await scheduleRuleBox.clear();
    await occurrenceBox.clear();
  });

  tearDownAll(() async {
    await Hive.close();
  });

  Account liability(String id, {bool archived = false}) => Account(
        id: id,
        bookId: 'book-1',
        memberId: 'member-1',
        name: id,
        type: 'loan',
        currency: 'EGP',
        createdAt: DateTime(2026, 1, 1),
        group: AccountGroup.liabilities,
        nature: AccountNature.liability,
        isArchived: archived,
      );

  Commitment payment(
    String id,
    String liabilityId,
    String ruleId, {
    bool archived = false,
    CommitmentStatus status = CommitmentStatus.active,
  }) =>
      Commitment(
        id: id,
        title: id,
        type: CommitmentType.liabilityPayment,
        status: status,
        amount: Money.parse('100'),
        amountMode: CommitmentAmountMode.fixed,
        scheduleRuleId: ruleId,
        liabilityAccountId: liabilityId,
        isArchived: archived,
      );

  ScheduleRule rule(String id, DateTime dueDate, Frequency frequency) =>
      ScheduleRule(
        id: id,
        frequency: frequency,
        startDate: dueDate,
        nextDueDate: dueDate,
      );

  test(
    'projects current liability balance and next payment without mutation',
    () async {
      final dueDate = DateTime(2026, 9, 15);

      final account = liability('loan-1');

      final schedule = rule('rule-1', dueDate, Frequency.monthly);

      final commitment = payment('payment-1', account.id, schedule.id);

      await accountBox.put(account.id, account);

      await txBox.put(
        'opening',
        Transaction(
          id: 'opening',
          amount: 1000,
          type: TransactionType.initialBalance,
          toAccountId: account.id,
          date: DateTime(2026, 1, 1),
        ),
      );

      await scheduleRuleBox.put(schedule.id, schedule);

      await commitmentBox.put(commitment.id, commitment);

      final beforeOccurrences = occurrenceBox.length;

      final summaries = service.getDebtSummaries(
        today: DateTime(2026, 9, 13),
      );

      expect(summaries, hasLength(1));

      expect(summaries.single.outstanding, Money.parse('1000'));

      expect(summaries.single.nextPayment?.id, commitment.id);

      expect(summaries.single.scheduleRule?.id, schedule.id);

      expect(
        summaries.single.paymentState,
        ScheduledActionState.upcoming,
      );

      expect(occurrenceBox.length, beforeOccurrences);
    },
  );

  test(
    'selects earliest active liability payment and ignores archived payments',
    () async {
      final account = liability('loan-1');

      final later =
          rule('later', DateTime(2026, 10, 1), Frequency.monthly);

      final earlier =
          rule('earlier', DateTime(2026, 9, 20), Frequency.monthly);

      await accountBox.put(account.id, account);

      await scheduleRuleBox.put(later.id, later);

      await scheduleRuleBox.put(earlier.id, earlier);

      await commitmentBox.put(
        'archived',
        payment(
          'archived',
          account.id,
          later.id,
          archived: true,
        ),
      );

      await commitmentBox.put(
        'later-payment',
        payment(
          'later-payment',
          account.id,
          later.id,
        ),
      );

      await commitmentBox.put(
        'earlier-payment',
        payment(
          'earlier-payment',
          account.id,
          earlier.id,
        ),
      );

      final summary = service.getDebtSummary(
        account.id,
        today: DateTime(2026, 9, 13),
      );

      expect(summary?.nextPayment?.id, 'earlier-payment');

      expect(summary?.scheduleRule?.id, earlier.id);
    },
  );

  test(
    'returns overdue state for a payment whose due date has passed',
    () async {
      final account = liability('loan-overdue');

      final schedule =
          rule('rule-overdue', DateTime(2026, 9, 10), Frequency.monthly);

      final commitment =
          payment('payment-overdue', account.id, schedule.id);

      await accountBox.put(account.id, account);

      await scheduleRuleBox.put(schedule.id, schedule);

      await commitmentBox.put(commitment.id, commitment);

      final summary = service.getDebtSummary(
        account.id,
        today: DateTime(2026, 9, 13),
      );

      expect(summary?.nextPayment?.id, commitment.id);

      expect(
        summary?.paymentState,
        ScheduledActionState.overdue,
      );
    },
  );

  test(
    'returns outstanding only when liability has no payment commitment',
    () async {
      final account = liability('loan-no-payment');

      await accountBox.put(account.id, account);

      await txBox.put(
        'opening',
        Transaction(
          id: 'opening',
          amount: 750,
          type: TransactionType.initialBalance,
          toAccountId: account.id,
          date: DateTime(2026, 1, 1),
        ),
      );

      final summary = service.getDebtSummary(
        account.id,
        today: DateTime(2026, 9, 13),
      );

      expect(summary, isNotNull);

      expect(summary!.outstanding, Money.parse('750'));

      expect(summary.nextPayment, isNull);

      expect(summary.scheduleRule, isNull);

      expect(summary.occurrence, isNull);

      expect(summary.paymentState, isNull);
    },
  );

  test(
    'excludes archived liability accounts',
    () async {
      await accountBox.put('active', liability('active'));

      await accountBox.put(
        'archived',
        liability('archived', archived: true),
      );

      final summaries = service.getDebtSummaries(
        today: DateTime(2026, 9, 13),
      );

      expect(
        summaries.map((e) => e.liabilityAccount.id),
        ['active'],
      );
    },
  );

  test(
    'does not expose a completed one-time occurrence as next payment',
    () async {
      final account = liability('loan-one-time');

      final dueDate = DateTime(2026, 9, 12);

      final schedule =
          rule('rule-one-time', dueDate, Frequency.oneTime);

      final commitment =
          payment('payment-one-time', account.id, schedule.id);

      final occurrence = ScheduleOccurrence(
        id: ScheduleOccurrence.idFor(
          scheduleRuleId: schedule.id,
          dueDate: schedule.nextDueDate,
        ),
        scheduleRuleId: schedule.id,
        dueDate: dueDate,
        status: ScheduleOccurrenceStatus.completed,
      );

      await accountBox.put(account.id, account);

      await scheduleRuleBox.put(schedule.id, schedule);

      await commitmentBox.put(commitment.id, commitment);

      await occurrenceBox.put(occurrence.id, occurrence);

      final summary = service.getDebtSummary(
        account.id,
        today: DateTime(2026, 9, 13),
      );

      expect(summary, isNotNull);

      expect(summary!.nextPayment, isNull);

      expect(summary.scheduleRule, isNull);

      expect(summary.occurrence, isNull);

      expect(summary.paymentState, isNull);
    },
  );
}