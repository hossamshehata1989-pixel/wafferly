import 'package:wafferly/core/money/money.dart';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:wafferly/bootstrap/financial_engine_bootstrap.dart';
import 'package:wafferly/core/planning/infrastructure/repositories/memory_allocation_repository.dart';
import 'package:wafferly/core/planning/services/available_balance_projection_service.dart';
import 'package:wafferly/financial_engine/commands/shared/transaction_metadata.dart';
import 'package:wafferly/financial_engine/commands/transfer/transfer_intent.dart';
import 'package:wafferly/financial_engine/execution_context/execution_context.dart';
import 'package:wafferly/financial_engine/operations/transfer_operation.dart';
import 'package:wafferly/financial_engine/results/operation_result.dart';
import 'package:wafferly/models/account.dart';
import 'package:wafferly/models/enums/account_enums.dart';
import 'package:wafferly/models/transaction.dart';
import 'package:wafferly/constants/transaction_constants.dart';
import 'package:wafferly/models/ledger_account.dart';
import 'package:wafferly/models/enums/ledger_account_type.dart';
import 'package:wafferly/models/ledger_entry.dart';
import 'package:wafferly/models/enums/entry_type.dart';
import 'package:wafferly/models/enums/ledger_purpose.dart';
import 'package:wafferly/services/balance_service.dart';
import 'package:wafferly/services/ledger_account_seeder.dart';

void main() {
  late Directory testDirectory;
  late Box<Transaction> transactionBox;
  late Box<Account> accountsBox;
  late Box<LedgerEntry> ledgerBox;
  late Box<LedgerAccount> ledgerAccountsBox;

  setUpAll(() async {
    testDirectory = await Directory.systemTemp.createTemp(
      'wafferly_transfer_pipeline_test_',
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

    transactionBox = await Hive.openBox<Transaction>('transactions');
    accountsBox = await Hive.openBox<Account>('accounts');
    ledgerBox = await Hive.openBox<LedgerEntry>('ledger_entries');
    ledgerAccountsBox =
        await Hive.openBox<LedgerAccount>('ledger_accounts');

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
      'bank',
      Account(
        id: 'bank',
        bookId: 'default',
        memberId: 'owner',
        name: 'Bank',
        type: 'bank',
        nature: AccountNature.asset,
        currency: 'EGP',
        createdAt: DateTime(2026, 1, 1),
        group: AccountGroup.values.first,
      ),
    );

    // Seed the source account with an opening balance so the
    // BalanceDomainGuard can validate the transfer.
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

  test(
    'Transfer operation creates one balanced journal entry and ledger projection',
    () async {
      final allocationRepository = MemoryAllocationRepository();

      final availableBalanceProjectionService =
          AvailableBalanceProjectionService(
        allocationRepository: allocationRepository,
      );

      final balanceService = BalanceService(
        availableBalanceProjectionService: availableBalanceProjectionService,
      );

      final context = FinancialEngineBootstrap.create(
        balanceService: balanceService,
        transactionBox: transactionBox,
      );

      const executionContext = ExecutionContext(
        idempotencyKey: 'transfer-test',
      );

      final operation = TransferOperation(
        intent: TransferIntent(
          fromAccountId: 'wallet',
          toAccountId: 'bank',
          amount: Money.fromDouble(100),
        ),
        metadata: TransactionMetadata(
          occurredAt: DateTime(2026, 1, 1),
          paymentMethod: 'cash',
          currencyCode: 'EGP',
        ),
        context: executionContext,
      );

      final result = await context.engine.execute(
        operation,
        executionContext,
      );

      expect(result, isA<OperationSucceeded>());

      // Accounting intent produced by the Planner.
      expect(context.repository.entries.length, 1);

      final journalEntry = context.repository.entries.single;

      expect(journalEntry.lines.length, 2);

      final debit = journalEntry.lines.first;
      final credit = journalEntry.lines.last;

      expect(debit.accountId, 'bank');
      expect(debit.debit, Money.fromDouble(100));

      expect(credit.accountId, 'wallet');
      expect(credit.credit, Money.fromDouble(100));

      // Persisted transaction created by the canonical Transaction write path.
      final transaction = transactionBox.values.singleWhere(
        (item) => item.type == 'transfer',
      );

      // Persisted Ledger projection created from the FinancialTransactionRecord.
      final ledgerEntries = ledgerBox.values
          .where((item) => item.transactionId == transaction.id)
          .toList();

      expect(ledgerEntries.length, 2);

      final ledgerDebit = ledgerEntries.singleWhere(
        (item) => item.entryType == EntryType.debit,
      );
      final ledgerCredit = ledgerEntries.singleWhere(
        (item) => item.entryType == EntryType.credit,
      );

      expect(ledgerDebit.accountId, 'bank');
      expect(ledgerDebit.amount, 100);
      expect(ledgerDebit.purpose, LedgerPurpose.transfer);

      expect(ledgerCredit.accountId, 'wallet');
      expect(ledgerCredit.amount, 100);
      expect(ledgerCredit.purpose, LedgerPurpose.transfer);
    },
  );
}
