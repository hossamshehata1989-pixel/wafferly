import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:wafferly/bootstrap/financial_engine_bootstrap.dart';
import 'package:wafferly/core/planning/infrastructure/repositories/memory_allocation_repository.dart';
import 'package:wafferly/core/planning/services/available_balance_projection_service.dart';
import 'package:wafferly/constants/transaction_constants.dart';
import 'package:wafferly/financial_engine/commands/shared/transaction_metadata.dart';
import 'package:wafferly/financial_engine/execution_context/execution_context.dart';
import 'package:wafferly/financial_engine/operations/commitment_payment_operation.dart';
import 'package:wafferly/financial_engine/results/operation_result.dart';
import 'package:wafferly/models/account.dart';
import 'package:wafferly/models/enums/account_enums.dart';
import 'package:wafferly/models/enums/entry_type.dart';
import 'package:wafferly/models/enums/ledger_purpose.dart';
import 'package:wafferly/models/ledger_account.dart';
import 'package:wafferly/models/ledger_entry.dart';
import 'package:wafferly/models/enums/ledger_account_type.dart';
import 'package:wafferly/models/transaction.dart';
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
      'wafferly_commitment_payment_execution_test_',
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
    ledgerAccountsBox = await Hive.openBox<LedgerAccount>('ledger_accounts');

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
        currency: 'EGP',
        createdAt: DateTime(2026, 1, 1),
        group: AccountGroup.liquidity,
        nature: AccountNature.asset,
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
        currency: 'EGP',
        createdAt: DateTime(2026, 1, 1),
        group: AccountGroup.liabilities,
        nature: AccountNature.liability,
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

  test(
    'Commitment payment executes as scheduled transfer to liability account',
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
        idempotencyKey: 'commitment-payment-execution-test',
      );

      final operation = CommitmentPaymentOperation(
        sourceAccountId: 'wallet',
        liabilityAccountId: 'loan',
        commitmentId: 'commitment-1',
        amount: 100,
        metadata: TransactionMetadata(
          occurredAt: DateTime(2026, 1, 10),
          paymentMethod: 'cash',
          currencyCode: 'EGP',
          note: 'Scheduled loan payment',
        ),
        context: executionContext,
      );

      final result1 = await context.engine.execute(
        operation,
        executionContext,
      );
      final result2 = await context.engine.execute(
        operation,
        executionContext,
      );

      expect(result1, isA<OperationSucceeded>());
      expect(identical(result1, result2), isTrue);

      final transactions = transactionBox.values
          .where((item) => item.type == TransactionType.transfer)
          .toList();

      expect(transactions.length, 1);

      final transaction = transactions.single;
      expect(transaction.fromAccountId, 'wallet');
      expect(transaction.toAccountId, 'loan');
      expect(transaction.amount, 100);
      expect(transaction.source, TransactionSource.scheduled);
      expect(transaction.note, 'Scheduled loan payment');

      expect(context.repository.entries.length, 1);
      final journalEntry = context.repository.entries.single;
      expect(journalEntry.lines.length, 2);

      final debit = journalEntry.lines.first;
      final credit = journalEntry.lines.last;

      expect(debit.accountId, 'loan');
      expect(debit.debit, 100);
      expect(credit.accountId, 'wallet');
      expect(credit.credit, 100);

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

      expect(ledgerDebit.accountId, 'loan');
      expect(ledgerDebit.amount, 100);
      expect(ledgerDebit.purpose, LedgerPurpose.transfer);
      expect(ledgerCredit.accountId, 'wallet');
      expect(ledgerCredit.amount, 100);
      expect(ledgerCredit.purpose, LedgerPurpose.transfer);
    },
  );
}
