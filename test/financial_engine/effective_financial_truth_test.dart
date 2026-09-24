import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:wafferly/constants/transaction_constants.dart';
import 'package:wafferly/models/account.dart';
import 'package:wafferly/models/enums/account_enums.dart';
import 'package:wafferly/models/transaction.dart';
import 'package:wafferly/services/balance_service.dart';
import 'package:wafferly/services/financial_effective_transaction_query.dart';
import 'package:wafferly/services/transaction_service.dart';

void main() {
  late Directory testDirectory;
  late Box<Transaction> transactionBox;
  late Box<Map> correctionBox;
  late Box<Map> invalidationBox;
  late Box<Account> accountsBox;

  setUpAll(() async {
    testDirectory = await Directory.systemTemp.createTemp(
      'wafferly_effective_truth_test_',
    );
    Hive.init(testDirectory.path);

    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(AccountAdapter());
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(AccountNatureAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(AccountGroupAdapter());
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(TransactionAdapter());
    }

    transactionBox = await Hive.openBox<Transaction>('transactions');
    correctionBox = await Hive.openBox<Map>('financial_corrections');
    invalidationBox = await Hive.openBox<Map>('financial_invalidations');
    accountsBox = await Hive.openBox<Account>('accounts');
  });

  tearDownAll(() async {
    await Hive.close();
    if (await testDirectory.exists()) {
      await testDirectory.delete(recursive: true);
    }
  });

  setUp(() async {
    await transactionBox.clear();
    await correctionBox.clear();
    await invalidationBox.clear();
    await accountsBox.clear();

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

    await transactionBox.put(
      'opening',
      Transaction(
        id: 'opening',
        amount: 1000,
        type: TransactionType.initialBalance,
        toAccountId: 'wallet',
        date: DateTime(2026, 1, 1),
        currencyCode: 'EGP',
      ),
    );
  });

  Transaction expense({required String id, required double amount}) {
    return Transaction(
      id: id,
      amount: amount,
      type: TransactionType.expense,
      fromAccountId: 'wallet',
      categoryId: 'bills',
      date: DateTime(2026, 1, 2),
      currencyCode: 'EGP',
    );
  }

  Map<String, dynamic> correction({
    required String correctionId,
    required String originalId,
    required String correctedId,
    required double beforeAmount,
    required double afterAmount,
  }) {
    return {
      'correctionId': correctionId,
      'originalTransactionId': originalId,
      'before': {
        'transactionId': originalId,
        'type': TransactionType.expense,
        'fromAccountId': 'wallet',
        'toAccountId': null,
        'categoryId': 'bills',
        'subCategoryId': null,
        'amount': beforeAmount,
        'currencyCode': 'EGP',
        'paymentMethod': 'cash',
        'occurredAt': DateTime(2026, 1, 2).toIso8601String(),
        'note': null,
        'isExceptional': false,
        'source': 'manual',
        'actorMemberId': null,
        'commitmentId': null,
        'scheduleRuleId': null,
        'occurrenceId': null,
      },
      'after': {
        'transactionId': correctedId,
        'type': TransactionType.expense,
        'fromAccountId': 'wallet',
        'toAccountId': null,
        'categoryId': 'bills',
        'subCategoryId': null,
        'amount': afterAmount,
        'currencyCode': 'EGP',
        'paymentMethod': 'cash',
        'occurredAt': DateTime(2026, 1, 2).toIso8601String(),
        'note': null,
        'isExceptional': false,
        'source': 'manual',
        'actorMemberId': null,
        'commitmentId': null,
        'scheduleRuleId': null,
        'occurrenceId': null,
      },
    };
  }

  test('corrected original is history-only and corrected transaction is effective', () async {
    await transactionBox.put('tx-200', expense(id: 'tx-200', amount: 200));
    await transactionBox.put('tx-500', expense(id: 'tx-500', amount: 500));
    await correctionBox.put(
      'correction-1',
      correction(
        correctionId: 'correction-1',
        originalId: 'tx-200',
        correctedId: 'tx-500',
        beforeAmount: 200,
        afterAmount: 500,
      ),
    );

    final query = const FinancialEffectiveTransactionQuery();
    expect(query.isEffective('tx-200'), isFalse);
    expect(query.isEffective('tx-500'), isTrue);

    final transactions = TransactionService.instance.getAllTransactions();
    expect(transactions.map((tx) => tx.id), contains('tx-500'));
    expect(transactions.map((tx) => tx.id), isNot(contains('tx-200')));

    final balance = BalanceService().getBalance('wallet');
    expect(balance, 500);
  });

  test('correction chains keep only the latest transaction effective', () async {
    await transactionBox.put('tx-200', expense(id: 'tx-200', amount: 200));
    await transactionBox.put('tx-500', expense(id: 'tx-500', amount: 500));
    await transactionBox.put('tx-700', expense(id: 'tx-700', amount: 700));

    await correctionBox.put(
      'correction-1',
      correction(
        correctionId: 'correction-1',
        originalId: 'tx-200',
        correctedId: 'tx-500',
        beforeAmount: 200,
        afterAmount: 500,
      ),
    );
    await correctionBox.put(
      'correction-2',
      correction(
        correctionId: 'correction-2',
        originalId: 'tx-500',
        correctedId: 'tx-700',
        beforeAmount: 500,
        afterAmount: 700,
      ),
    );

    final query = const FinancialEffectiveTransactionQuery();
    expect(query.isEffective('tx-200'), isFalse);
    expect(query.isEffective('tx-500'), isFalse);
    expect(query.isEffective('tx-700'), isTrue);

    final transactions = TransactionService.instance.getAllTransactions();
    expect(transactions.map((tx) => tx.id), ['tx-700', 'opening']);
    expect(BalanceService().getBalance('wallet'), 300);
  });

  test('invalidating the current corrected transaction removes its financial effect', () async {
    await transactionBox.put('tx-200', expense(id: 'tx-200', amount: 200));
    await transactionBox.put('tx-500', expense(id: 'tx-500', amount: 500));
    await correctionBox.put(
      'correction-1',
      correction(
        correctionId: 'correction-1',
        originalId: 'tx-200',
        correctedId: 'tx-500',
        beforeAmount: 200,
        afterAmount: 500,
      ),
    );
    await invalidationBox.put(
      'invalidation-1',
      {
        'invalidationId': 'invalidation-1',
        'originalTransactionId': 'tx-500',
        'before': <String, dynamic>{},
      },
    );

    final query = const FinancialEffectiveTransactionQuery();
    expect(query.isEffective('tx-200'), isFalse);
    expect(query.isEffective('tx-500'), isFalse);
    expect(TransactionService.instance.getAllTransactions().map((tx) => tx.id),
        ['opening']);
    expect(BalanceService().getBalance('wallet'), 1000);
  });

  test('effective read semantics do not mutate immutable transaction history', () async {
    await transactionBox.put('tx-200', expense(id: 'tx-200', amount: 200));
    await transactionBox.put('tx-500', expense(id: 'tx-500', amount: 500));
    await correctionBox.put(
      'correction-1',
      correction(
        correctionId: 'correction-1',
        originalId: 'tx-200',
        correctedId: 'tx-500',
        beforeAmount: 200,
        afterAmount: 500,
      ),
    );

    final original = transactionBox.get('tx-200');
    expect(original, isNotNull);
    expect(original!.amount, 200);
    expect(transactionBox.length, 3);
    expect(correctionBox.length, 1);
  });
}
