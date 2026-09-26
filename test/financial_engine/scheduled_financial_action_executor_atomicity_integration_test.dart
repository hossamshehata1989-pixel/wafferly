import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:wafferly/bootstrap/financial_engine_bootstrap.dart';
import 'package:wafferly/core/money/money.dart';
import 'package:wafferly/constants/transaction_constants.dart';
import 'package:wafferly/core/planning/infrastructure/repositories/memory_allocation_repository.dart';
import 'package:wafferly/core/planning/services/available_balance_projection_service.dart';
import 'package:wafferly/financial_engine/engine/financial_operation_engine.dart';
import 'package:wafferly/features/financial_action_center/services/financial_action_executor.dart';
import 'package:wafferly/models/account.dart';
import 'package:wafferly/models/commitment.dart';
import 'package:wafferly/models/enums/account_enums.dart';
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
import 'package:wafferly/models/transaction.dart';
import 'package:wafferly/models/enums/entry_type.dart';
import 'package:wafferly/models/enums/ledger_account_type.dart';
import 'package:wafferly/models/enums/ledger_purpose.dart';
import 'package:wafferly/models/ledger_account.dart';
import 'package:wafferly/models/ledger_entry.dart';
import 'package:wafferly/services/balance_service.dart';
import 'package:wafferly/services/ledger_account_seeder.dart';
import 'package:wafferly/services/schedule_occurrence_service.dart';
import 'package:wafferly/services/schedule_rule_service.dart';
import 'package:wafferly/services/scheduled_execution_journal.dart';

class _FailOnceOccurrenceService extends ScheduleOccurrenceService {
  bool failCompletion = true;

  _FailOnceOccurrenceService({required super.ruleService});

  @override
  Future<ScheduleOccurrence> completeOccurrence(
    ScheduleOccurrence occurrence,
  ) {
    if (failCompletion) {
      failCompletion = false;
      throw StateError('simulated occurrence completion failure');
    }
    return super.completeOccurrence(occurrence);
  }
}

void main() {
  late Directory testDirectory;
  late Box<Transaction> transactionBox;
  late Box<Map> idempotencyBox;
  late Box<Account> accountsBox;
  late Box<LedgerEntry> ledgerBox;
  late Box<LedgerAccount> ledgerAccountsBox;
  late Box<ScheduleRule> scheduleRuleBox;
  late Box<ScheduleOccurrence> occurrenceBox;
  late Box<Map> journalBox;

  setUpAll(() async {
    testDirectory = await Directory.systemTemp.createTemp(
      'wafferly_scheduled_executor_atomicity_',
    );
    Hive.init(testDirectory.path);

    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(AccountAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(AccountNatureAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(AccountGroupAdapter());
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(TransactionAdapter());
    if (!Hive.isAdapterRegistered(20)) Hive.registerAdapter(EntryTypeAdapter());
    if (!Hive.isAdapterRegistered(21)) Hive.registerAdapter(LedgerPurposeAdapter());
    if (!Hive.isAdapterRegistered(22)) Hive.registerAdapter(LedgerEntryAdapter());
    if (!Hive.isAdapterRegistered(30)) Hive.registerAdapter(LedgerAccountTypeAdapter());
    if (!Hive.isAdapterRegistered(31)) Hive.registerAdapter(LedgerAccountAdapter());
    if (!Hive.isAdapterRegistered(91)) Hive.registerAdapter(CommitmentTypeAdapter());
    if (!Hive.isAdapterRegistered(92)) Hive.registerAdapter(CommitmentStatusAdapter());
    if (!Hive.isAdapterRegistered(93)) Hive.registerAdapter(CommitmentAmountModeAdapter());
    if (!Hive.isAdapterRegistered(94)) Hive.registerAdapter(FrequencyAdapter());
    if (!Hive.isAdapterRegistered(95)) Hive.registerAdapter(ScheduleRuleAdapter());
    if (!Hive.isAdapterRegistered(96)) Hive.registerAdapter(CommitmentAdapter());
    if (!Hive.isAdapterRegistered(98)) Hive.registerAdapter(ScheduleOccurrenceAdapter());
    if (!Hive.isAdapterRegistered(99)) Hive.registerAdapter(ScheduleOccurrenceStatusAdapter());

    transactionBox = await Hive.openBox<Transaction>('transactions');
    idempotencyBox = await Hive.openBox<Map>('financial_idempotency');
    accountsBox = await Hive.openBox<Account>('accounts');
    ledgerBox = await Hive.openBox<LedgerEntry>('ledger_entries');
    ledgerAccountsBox = await Hive.openBox<LedgerAccount>('ledger_accounts');
    scheduleRuleBox = await Hive.openBox<ScheduleRule>('schedule_rules');
    occurrenceBox = await Hive.openBox<ScheduleOccurrence>('schedule_occurrences');
    journalBox = await Hive.openBox<Map>(ScheduledExecutionJournal.boxName);
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
    await idempotencyBox.clear();
    await accountsBox.clear();
    await ledgerBox.clear();
    await ledgerAccountsBox.clear();
    await scheduleRuleBox.clear();
    await occurrenceBox.clear();
    await journalBox.clear();

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
    'production executor resumes after scheduling failure without duplicating financial truth',
    (tester) async {
      final now = DateTime.now();
      final dueDate = DateTime(now.year, now.month, now.day);
      final rule = ScheduleRule(
        id: 'rule-atomicity',
        frequency: Frequency.daily,
        startDate: dueDate,
        nextDueDate: dueDate,
      );
      await tester.runAsync(() async {
        await scheduleRuleBox.put(rule.id, rule);
      });

      final commitment = Commitment(
        id: 'commitment-atomicity',
        title: 'Atomicity Test Payment',
        type: CommitmentType.liabilityPayment,
        status: CommitmentStatus.active,
        amount: Money.parse('100'),
        amountMode: CommitmentAmountMode.fixed,
        scheduleRuleId: rule.id,
        sourceAccountId: 'wallet',
        liabilityAccountId: 'loan',
        notes: 'Atomicity test',
      );

      final occurrence = ScheduleOccurrence(
        id: ScheduleOccurrence.idFor(
          scheduleRuleId: rule.id,
          dueDate: dueDate,
        ),
        scheduleRuleId: rule.id,
        dueDate: dueDate,
      );
      await tester.runAsync(() async {
        await occurrenceBox.put(occurrence.id, occurrence);
      });

      final action = ScheduledActionExecutionContext(
        action: ScheduledAction(
          id: 'action-atomicity',
          kind: ScheduledActionKind.liabilityPayment,
          state: ScheduledActionState.due,
          title: commitment.title,
          subtitle: 'Atomicity test',
          amount: 100,
          dueDate: dueDate,
          sourceAccountId: 'wallet',
          liabilityAccountId: 'loan',
          commitmentId: commitment.id,
        ),
        commitment: commitment,
        scheduleRule: rule,
        occurrence: occurrence,
      );

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
        idempotencyBox: idempotencyBox,
      );

      final occurrenceService = _FailOnceOccurrenceService(
        ruleService: ScheduleRuleService(),
      );
      final executor = FinancialActionExecutor(
        engine: engineContext.engine,
        occurrenceService: occurrenceService,
      );

      BuildContext? capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final firstResult = await tester.runAsync(() async {
        return executor.execute(capturedContext!, action);
      });

      expect(firstResult, isFalse);
      expect(
        transactionBox.values.where((t) => t.type == 'transfer'),
        hasLength(1),
      );
      expect(
        journalBox.get(occurrence.id)!['state'],
        ScheduledExecutionJournal.stateFinancialSucceeded,
      );
      expect(
        occurrenceBox.get(occurrence.id)?.status,
        ScheduleOccurrenceStatus.pending,
      );

      // The same production executor path is retried with the same occurrence.
      // The coordinator must resume scheduling state without calling the
      // financial operation a second time.
      final secondResult = await tester.runAsync(() async {
        return executor.execute(capturedContext!, action);
      });

      expect(secondResult, isTrue);
      expect(
        transactionBox.values.where((t) => t.type == 'transfer'),
        hasLength(1),
      );
      expect(
        occurrenceBox.get(occurrence.id)?.status,
        ScheduleOccurrenceStatus.completed,
      );
      expect(
        journalBox.get(occurrence.id)!['state'],
        ScheduledExecutionJournal.stateCompleted,
      );
    },
  );
}

