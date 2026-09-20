import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import 'package:wafferly/bootstrap/financial_engine_bootstrap.dart';
import 'package:wafferly/core/money/money.dart';
import 'package:wafferly/core/planning/infrastructure/repositories/memory_allocation_repository.dart';
import 'package:wafferly/core/planning/services/available_balance_projection_service.dart';
import 'package:wafferly/financial_engine/engine/financial_operation_engine.dart';
import 'package:wafferly/models/account.dart';
import 'package:wafferly/models/commitment.dart';
import 'package:wafferly/models/enums/account_enums.dart';
import 'package:wafferly/models/enums/commitment_amount_mode.dart';
import 'package:wafferly/models/enums/commitment_status.dart';
import 'package:wafferly/models/enums/commitment_type.dart';
import 'package:wafferly/models/enums/entry_type.dart';
import 'package:wafferly/models/enums/frequency.dart';
import 'package:wafferly/models/enums/ledger_account_type.dart';
import 'package:wafferly/models/enums/ledger_purpose.dart';
import 'package:wafferly/models/enums/schedule_occurrence_status.dart';
import 'package:wafferly/models/ledger_account.dart';
import 'package:wafferly/models/ledger_entry.dart';
import 'package:wafferly/models/schedule_occurrence.dart';
import 'package:wafferly/models/schedule_rule.dart';
import 'package:wafferly/models/transaction.dart';
import 'package:wafferly/services/balance_service.dart';
import 'package:wafferly/services/ledger_account_seeder.dart';
import 'package:wafferly/features/financial_action_center/financial_action_center.dart';
import 'package:wafferly/constants/transaction_constants.dart';
void main() {
  late Directory testDirectory;
  late Box<Transaction> transactionBox;
  late Box<Account> accountsBox;
  late Box<LedgerEntry> ledgerBox;
  late Box<LedgerAccount> ledgerAccountsBox;
  late Box<Commitment> commitmentBox;
  late Box<ScheduleRule> scheduleRuleBox;
  late Box<ScheduleOccurrence> occurrenceBox;

  setUpAll(() async {

    testDirectory = await Directory.systemTemp.createTemp(
      'wafferly_commitment_ui_execution_',
    );


    Hive.init(testDirectory.path);


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
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(EntryTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(21)) {
      Hive.registerAdapter(LedgerPurposeAdapter());
    }
    if (!Hive.isAdapterRegistered(22)) {
      Hive.registerAdapter(LedgerEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(30)) {
      Hive.registerAdapter(LedgerAccountTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(31)) {
      Hive.registerAdapter(LedgerAccountAdapter());
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


    transactionBox = await Hive.openBox<Transaction>('transactions');

    accountsBox = await Hive.openBox<Account>('accounts');

    ledgerBox = await Hive.openBox<LedgerEntry>('ledger_entries');

    ledgerAccountsBox = await Hive.openBox<LedgerAccount>('ledger_accounts');

    commitmentBox = await Hive.openBox<Commitment>('commitments');

    scheduleRuleBox = await Hive.openBox<ScheduleRule>('schedule_rules');

    occurrenceBox =
        await Hive.openBox<ScheduleOccurrence>('schedule_occurrences');


    await LedgerAccountSeeder().seedIfNeeded();

  });

  tearDownAll(() async {


    await Hive.close();


    if (await testDirectory.exists()) {

      await testDirectory.delete(recursive: true);

    }

  });

  setUp(() async {

    await transactionBox.clear();
    await accountsBox.clear();
    await ledgerBox.clear();
    await ledgerAccountsBox.clear();
    await commitmentBox.clear();
    await scheduleRuleBox.clear();
    await occurrenceBox.clear();


    await accountsBox.put(
      'wallet',
      Account(
        id: 'wallet',
        bookId: 'default',
        memberId: 'owner',
        name: 'Wallet',
        type: 'wallet',
        nature: AccountNature.asset,
        currency: 'EGP',
        createdAt: DateTime(2026, 1, 1),
        group: AccountGroup.values.first,
      ),
    );


    await accountsBox.put(
      'loan',
      Account(
        id: 'loan',
        bookId: 'default',
        memberId: 'owner',
        name: 'Loan',
        type: 'loan',
        nature: AccountNature.liability,
        currency: 'EGP',
        createdAt: DateTime(2026, 1, 1),
        group: AccountGroup.values.first,
      ),
    );


    await transactionBox.put(
      'initial-wallet-balance',
      Transaction(
        id: 'initial-wallet-balance',
        amount: 1000,
        type: TransactionType.initialBalance,
        toAccountId: 'wallet',
        date: DateTime(2026, 1, 1),
        paymentMethod: 'cash',
        currencyCode: 'EGP',
      ),
    );

  });

  testWidgets(
    'Financial Action Center executes a liability payment through the real engine',
    (tester) async {

      final dueDate = DateTime(2026, 9, 20);


      final rule = ScheduleRule(
        id: 'rule-loan-payment',
        frequency: Frequency.daily,
        startDate: dueDate,
        nextDueDate: dueDate,
      );


      final commitment = Commitment(
        id: 'commitment-loan-payment',
        title: 'Daily Loan Payment',
        type: CommitmentType.liabilityPayment,
        status: CommitmentStatus.active,
        amount: Money.parse('100'),
        amountMode: CommitmentAmountMode.fixed,
        scheduleRuleId: rule.id,
        sourceAccountId: 'wallet',
        liabilityAccountId: 'loan',
        notes: 'Scheduled loan installment',
      );



      // Real disk I/O (Hive) must run outside the fake-async zone that
      // testWidgets wraps this callback in, or the await never resolves.
      await tester.runAsync(() async {

        await scheduleRuleBox.put(rule.id, rule);



        await commitmentBox.put(commitment.id, commitment);

      });

      final allocationRepository = MemoryAllocationRepository();


      final balanceService = BalanceService(
        availableBalanceProjectionService:
            AvailableBalanceProjectionService(
          allocationRepository: allocationRepository,
        ),
      );


      final engineContext = FinancialEngineBootstrap.create(
        balanceService: balanceService,
        transactionBox: transactionBox,
      );


      var skipped = false;


      // initState() kicks off controller.loadActions() WITHOUT awaiting it
      // (fire-and-forget). That Future runs real Hive I/O
      // (ScheduleOccurrenceService.getOrCreateCurrentOccurrence) on the real
      // event loop, so pump() calls can return before it finishes — a fixed
      // number of pumps is not enough. Poll in real time, inside runAsync,
      // until the widget actually rebuilds with the loaded action (or time
      // out), instead of guessing how many pumps are "enough".
      await tester.runAsync(() async {
        await tester.pumpWidget(
          Provider<FinancialOperationEngine>.value(
            value: engineContext.engine,
            child: MaterialApp(
              home: Scaffold(
                body: FinancialActionCenter(
                  onSkip: () => skipped = true,
                ),
              ),
            ),
          ),
        );



        final stopwatch = Stopwatch()..start();
        while (find.text('Daily Loan Payment').evaluate().isEmpty &&
            stopwatch.elapsed < const Duration(seconds: 5)) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          await tester.pump();
        }

      });


      expect(
        find.text('Daily Loan Payment'),
        findsOneWidget,
      );



      expect(
        find.text('Loan Payment'),
        findsOneWidget,
      );



      expect(
        find.text('EGP 100'),
        findsOneWidget,
      );



      expect(
        find.text('Pay'),
        findsOneWidget,
      );



      // executor.execute() (awaited inside onExecute) runs real Hive I/O —
      // completeOccurrence() and advanceRuleAfterOccurrence(). tap() does
      // not wait for that Future, so poll in real time, inside runAsync,
      // until the item is actually removed from the list (which only
      // happens after execute() fully completes).
      await tester.runAsync(() async {
        await tester.tap(
          find.text('Pay').first,
        );



        final stopwatch = Stopwatch()..start();
        while (find.text('Daily Loan Payment').evaluate().isNotEmpty &&
            stopwatch.elapsed < const Duration(seconds: 5)) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          await tester.pump();
        }

      });


      final paymentTransactions = transactionBox.values
          .where((item) => item.type == 'transfer')
          .toList();

      expect(
        paymentTransactions,
        hasLength(1),
      );

      expect(
        paymentTransactions.single.fromAccountId,
        'wallet',
      );

      expect(
        paymentTransactions.single.toAccountId,
        'loan',
      );

      expect(
        paymentTransactions.single.amount,
        100,
      );

      expect(
        paymentTransactions.single.source,
        'scheduled',
      );

      expect(
        paymentTransactions.single.note,
        'Scheduled loan installment',
      );


      final storedOccurrence = occurrenceBox.values.single;

      expect(
        storedOccurrence.status,
        ScheduleOccurrenceStatus.completed,
      );


      final storedRule = scheduleRuleBox.get(rule.id)!;

      expect(
        storedRule.nextDueDate,
        DateTime(2026, 9, 21),
      );


      final ledgerEntries = ledgerBox.values
          .where(
            (item) =>
                item.transactionId ==
                paymentTransactions.single.id,
          )
          .toList();

      expect(
        ledgerEntries,
        hasLength(2),
      );

      expect(
        ledgerEntries.singleWhere(
          (item) => item.entryType == EntryType.debit,
        ).accountId,
        'loan',
      );

      expect(
        ledgerEntries.singleWhere(
          (item) => item.entryType == EntryType.credit,
        ).accountId,
        'wallet',
      );

      expect(
        ledgerEntries.every(
          (item) => item.purpose == LedgerPurpose.transfer,
        ),
        isTrue,
      );



      expect(
        find.text('Daily Loan Payment'),
        findsNothing,
      );

      expect(
        find.text('All caught up!'),
        findsOneWidget,
      );

      expect(
        skipped,
        isFalse,
      );

    },
  );
}
