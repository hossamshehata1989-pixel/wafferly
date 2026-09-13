import 'package:flutter_test/flutter_test.dart';

import 'package:hive/hive.dart';

import 'package:wafferly/core/money/money.dart';

import 'package:wafferly/models/account.dart';

import 'package:wafferly/models/commitment.dart';

import 'package:wafferly/models/debt/debt_summary.dart';

import 'package:wafferly/models/enums/account_enums.dart';

import 'package:wafferly/models/enums/commitment_amount_mode.dart';

import 'package:wafferly/models/enums/commitment_status.dart';

import 'package:wafferly/models/enums/commitment_type.dart';

import 'package:wafferly/models/enums/frequency.dart';

import 'package:wafferly/models/enums/schedule_occurrence_status.dart';

import 'package:wafferly/models/schedule_occurrence.dart';

import 'package:wafferly/models/schedule_rule.dart';

import 'package:wafferly/models/transaction.dart';

import 'package:wafferly/services/balance_service.dart';

import 'package:wafferly/services/debt_query_service.dart';
import 'package:wafferly/constants/transaction_constants.dart';
void main() {
  late Box<Transaction> transactions;

  late Box<Account> accounts;

  late Box<Commitment> commitments;

  late Box<ScheduleRule> rules;

  late Box<ScheduleOccurrence> occurrences;

  setUpAll(() async {
    Hive.init('test_debt_query_service');

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

    transactions = await Hive.openBox<Transaction>('transactions');

    accounts = await Hive.openBox<Account>('accounts');

    commitments = await Hive.openBox<Commitment>('commitments');

    rules = await Hive.openBox<ScheduleRule>('schedule_rules');

    occurrences =
        await Hive.openBox<ScheduleOccurrence>('schedule_occurrences');
  });

  tearDown(() async {
    await transactions.clear();
    await accounts.clear();
    await commitments.clear();
    await rules.clear();
    await occurrences.clear();
  });

  tearDownAll(() async {
    await Hive.close();
  });

  Account liabilityAccount() => Account(
        id: 'loan',
        bookId: 'default',
        memberId: 'owner',
        name: 'Loan',
        type: 'loan',
        nature: AccountNature.liability,
        currency: 'EGP',
        createdAt: DateTime(2026, 1, 1),
        group: AccountGroup.liabilities,
      );

  Commitment payment({
    required String id,
    required String ruleId,
    required String title,
  }) =>
      Commitment(
        id: id,
        title: title,
        type: CommitmentType.liabilityPayment,
        status: CommitmentStatus.active,
        amount: Money.parse('100'),
        amountMode: CommitmentAmountMode.fixed,
        scheduleRuleId: ruleId,
        sourceAccountId: 'wallet',
        liabilityAccountId: 'loan',
      );

  test(
    'projects current liability balance and next payment without mutation',
    () async {
      final dueDate = DateTime(2026, 9, 12);

      await accounts.put('loan', liabilityAccount());

      await transactions.put(
        'initial-loan',
        Transaction(
          id: 'initial-loan',
          amount: 1000,
          type: TransactionType.initialBalance,
          toAccountId: 'loan',
          date: DateTime(2026, 1, 1),
        ),
      );

      await rules.put(
        'rule-loan',
        ScheduleRule(
          id: 'rule-loan',
          frequency: Frequency.monthly,
          startDate: dueDate,
          nextDueDate: dueDate,
        ),
      );

      await commitments.put(
        'payment-loan',
        payment(
          id: 'payment-loan',
          ruleId: 'rule-loan',
          title: 'Loan Payment',
        ),
      );

      final service = DebtQueryService(
        balanceService: BalanceService(),
        accountBox: accounts,
        commitmentBox: commitments,
        scheduleRuleBox: rules,
        occurrenceBox: occurrences,
      );

      final result = service.getDebtSummary(
        'loan',
        today: dueDate,
      );

      expect(result, isA<DebtSummary>());

      expect(result!.outstanding, Money.parse('1000'));

      expect(result.nextPayment!.id, 'payment-loan');

      expect(result.scheduleRule!.nextDueDate, dueDate);

      expect(result.paymentState!.name, 'due');

      expect(occurrences.isEmpty, isTrue);
    },
  );

  test(
    'selects the earliest active liability payment and ignores archived payments',
    () async {
      await accounts.put('loan', liabilityAccount());

      await rules.putAll({
        'later': ScheduleRule(
          id: 'later',
          frequency: Frequency.monthly,
          startDate: DateTime(2026, 10, 1),
          nextDueDate: DateTime(2026, 10, 1),
        ),
        'earlier': ScheduleRule(
          id: 'earlier',
          frequency: Frequency.monthly,
          startDate: DateTime(2026, 9, 15),
          nextDueDate: DateTime(2026, 9, 15),
        ),
        'archived': ScheduleRule(
          id: 'archived',
          frequency: Frequency.monthly,
          startDate: DateTime(2026, 9, 1),
          nextDueDate: DateTime(2026, 9, 1),
        ),
      });

      await commitments.putAll({
        'later-payment': payment(
          id: 'later-payment',
          ruleId: 'later',
          title: 'Later',
        ),
        'earlier-payment': payment(
          id: 'earlier-payment',
          ruleId: 'earlier',
          title: 'Earlier',
        ),
        'archived-payment': payment(
          id: 'archived-payment',
          ruleId: 'archived',
          title: 'Archived',
        ).copyWith(isArchived: true),
      });

      final service = DebtQueryService(
        balanceService: BalanceService(),
        accountBox: accounts,
        commitmentBox: commitments,
        scheduleRuleBox: rules,
        occurrenceBox: occurrences,
      );

      final result = service.getDebtSummary(
        'loan',
        today: DateTime(2026, 9, 12),
      );

      expect(result!.nextPayment!.id, 'earlier-payment');

      expect(result.scheduleRule!.id, 'earlier');
    },
  );
}