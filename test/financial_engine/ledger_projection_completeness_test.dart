import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/constants/ledger_system_account_ids.dart';
import 'package:wafferly/constants/transaction_constants.dart';
import 'package:wafferly/core/money/money.dart';
import 'package:wafferly/financial_engine/domain/financial_correction_record.dart';
import 'package:wafferly/financial_engine/domain/financial_invalidation_record.dart';
import 'package:wafferly/financial_engine/domain/financial_transaction_record.dart';
import 'package:wafferly/models/enums/entry_type.dart';
import 'package:wafferly/models/enums/ledger_account_type.dart';
import 'package:wafferly/models/enums/ledger_purpose.dart';
import 'package:wafferly/models/ledger_account.dart';
import 'package:wafferly/models/ledger_entry.dart';
import 'package:wafferly/ports/ledger_port.dart';
import 'package:wafferly/services/category_ledger_mapper.dart';
import 'package:wafferly/services/ledger_projection_exceptions.dart';
import 'package:wafferly/services/ledger_projection_service.dart';

void main() {
  test(
    'asset opening balance projects debit to account and credit to equity',
    () async {
      final ledger = _MemoryLedgerPort();
      final service = LedgerProjectionService(ledgerPort: ledger);

      await service.projectRecord(
        _record(
          id: 'opening-asset',
          type: TransactionType.initialBalance,
          toAccountId: 'wallet',
          amount: 500,
        ),
      );

      expect(ledger.entries, hasLength(2));
      _expectBalanced(ledger.entries);
      expect(
        ledger.entries
            .singleWhere((entry) => entry.accountId == 'wallet')
            .entryType,
        EntryType.debit,
      );
      expect(
        ledger.entries
            .singleWhere(
              (entry) =>
                  entry.accountId ==
                  LedgerSystemAccountIds.openingBalanceEquity,
            )
            .entryType,
        EntryType.credit,
      );
      expect(
        ledger.entries.every((e) => e.purpose == LedgerPurpose.adjustment),
        isTrue,
      );
    },
  );

  test(
    'liability opening balance projects debit to equity and credit to account',
    () async {
      final ledger = _MemoryLedgerPort();
      final service = LedgerProjectionService(ledgerPort: ledger);

      await service.projectRecord(
        _record(
          id: 'opening-liability',
          type: TransactionType.initialBalance,
          fromAccountId: 'loan',
          amount: 900,
        ),
      );

      expect(ledger.entries, hasLength(2));
      _expectBalanced(ledger.entries);
      expect(
        ledger.entries
            .singleWhere((entry) => entry.accountId == 'loan')
            .entryType,
        EntryType.credit,
      );
      expect(
        ledger.entries
            .singleWhere(
              (entry) =>
                  entry.accountId ==
                  LedgerSystemAccountIds.openingBalanceEquity,
            )
            .entryType,
        EntryType.debit,
      );
    },
  );

  test('zero opening balance still emits its two genesis entries', () async {
    final ledger = _MemoryLedgerPort();
    final service = LedgerProjectionService(ledgerPort: ledger);

    await service.projectRecord(
      _record(
        id: 'opening-zero',
        type: TransactionType.initialBalance,
        toAccountId: 'wallet',
        amount: 0,
      ),
    );

    expect(ledger.entries, hasLength(2));
    _expectBalanced(ledger.entries);
    expect(ledger.entries.every((entry) => entry.amount == 0), isTrue);
  });

  test('balance reconciliation uses the canonical equity account', () async {
    final ledger = _MemoryLedgerPort();
    final service = LedgerProjectionService(ledgerPort: ledger);

    await service.projectRecord(
      _record(
        id: 'reconcile-asset',
        type: TransactionType.balanceReconciliation,
        fromAccountId: LedgerSystemAccountIds.balanceReconciliationEquity,
        toAccountId: 'wallet',
        amount: 75,
      ),
    );

    expect(ledger.entries, hasLength(2));
    _expectBalanced(ledger.entries);
    expect(
      ledger.entries
          .singleWhere((entry) => entry.accountId == 'wallet')
          .entryType,
      EntryType.debit,
    );
    expect(
      ledger.entries
          .singleWhere(
            (entry) =>
                entry.accountId ==
                LedgerSystemAccountIds.balanceReconciliationEquity,
          )
          .entryType,
      EntryType.credit,
    );
  });

  test('balance reconciliation rejects equity on both sides', () async {
    final ledger = _MemoryLedgerPort();
    final service = LedgerProjectionService(ledgerPort: ledger);

    await expectLater(
      service.projectRecord(
        _record(
          id: 'reconcile-invalid',
          type: TransactionType.balanceReconciliation,
          fromAccountId: LedgerSystemAccountIds.balanceReconciliationEquity,
          toAccountId: LedgerSystemAccountIds.balanceReconciliationEquity,
          amount: 25,
        ),
      ),
      throwsA(isA<StateError>()),
    );
    expect(ledger.entries, isEmpty);
  });

  test(
    'opening-balance invalidation reverses the original asset entries',
    () async {
      final ledger = _MemoryLedgerPort();
      final service = LedgerProjectionService(ledgerPort: ledger);

      await service.projectInvalidation(
        FinancialInvalidationRecord(
          invalidationId: 'invalidate-opening',
          originalTransactionId: 'opening-to-reverse',
          before: _record(
            id: 'opening-to-reverse',
            type: TransactionType.initialBalance,
            toAccountId: 'wallet',
            amount: 500,
          ),
        ),
      );

      expect(ledger.entries, hasLength(2));
      _expectBalanced(ledger.entries);
      expect(
        ledger.entries.every(
          (entry) => entry.transactionId == 'invalidate-opening',
        ),
        isTrue,
      );
      expect(
        ledger.entries
            .singleWhere((entry) => entry.accountId == 'wallet')
            .entryType,
        EntryType.credit,
      );
      expect(
        ledger.entries
            .singleWhere(
              (entry) =>
                  entry.accountId ==
                  LedgerSystemAccountIds.openingBalanceEquity,
            )
            .entryType,
        EntryType.debit,
      );
    },
  );

  test('correction writes one balanced four-entry projection group', () async {
    final ledger = _MemoryLedgerPort();
    final categoryMapper = CategoryLedgerMapper(
      lookup: (categoryId) => LedgerAccount(
        id: 'ledger-$categoryId',
        name: 'Expense $categoryId',
        type: LedgerAccountType.expense,
        categoryId: categoryId,
        isSystem: true,
      ),
    );
    final service = LedgerProjectionService(
      ledgerPort: ledger,
      categoryMapper: categoryMapper,
    );

    await service.projectCorrection(
      FinancialCorrectionRecord(
        correctionId: 'correction-1',
        originalTransactionId: 'expense-before',
        before: _record(
          id: 'expense-before',
          type: TransactionType.expense,
          fromAccountId: 'wallet',
          categoryId: 'food',
          amount: 100,
        ),
        after: _record(
          id: 'expense-after',
          type: TransactionType.expense,
          fromAccountId: 'wallet',
          categoryId: 'food',
          amount: 125,
        ),
      ),
    );

    expect(ledger.entries, hasLength(4));
    expect(
      ledger.entries.every((entry) => entry.transactionId == 'correction-1'),
      isTrue,
    );
    _expectBalanced(ledger.entries);
    expect(
      ledger.entries.where(
        (entry) => entry.purpose == LedgerPurpose.adjustment,
      ),
      hasLength(2),
    );
    expect(
      ledger.entries.where((entry) => entry.purpose == LedgerPurpose.expense),
      hasLength(2),
    );
  });

  test(
    'expense invalidation rejects a missing original category before ledger writes',
    () async {
      final ledger = _MemoryLedgerPort();
      final service = LedgerProjectionService(ledgerPort: ledger);

      await expectLater(
        service.projectInvalidation(
          FinancialInvalidationRecord(
            invalidationId: 'invalidate-expense-without-category',
            originalTransactionId: 'expense-without-category',
            before: _record(
              id: 'expense-without-category',
              type: TransactionType.expense,
              fromAccountId: 'wallet',
              categoryId: null,
              amount: 50,
            ),
          ),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            contains('must retain its original category ID'),
          ),
        ),
      );
      expect(ledger.entries, isEmpty);
    },
  );

  test('expense, income, and transfer projections are balanced', () async {
    final ledger = _MemoryLedgerPort();
    final categoryMapper = CategoryLedgerMapper(
      lookup: (categoryId) => LedgerAccount(
        id: 'ledger-$categoryId',
        name: 'Mapped $categoryId',
        type: categoryId == 'salary'
            ? LedgerAccountType.income
            : LedgerAccountType.expense,
        categoryId: categoryId,
        isSystem: true,
      ),
    );
    final service = LedgerProjectionService(
      ledgerPort: ledger,
      categoryMapper: categoryMapper,
    );

    await service.projectRecord(
      _record(
        id: 'expense-flow',
        type: TransactionType.expense,
        fromAccountId: 'wallet',
        categoryId: 'food',
        amount: 25,
      ),
    );
    await service.projectRecord(
      _record(
        id: 'income-flow',
        type: TransactionType.income,
        toAccountId: 'wallet',
        categoryId: 'salary',
        amount: 100,
      ),
    );
    await service.projectRecord(
      _record(
        id: 'transfer-flow',
        type: TransactionType.transfer,
        fromAccountId: 'wallet',
        toAccountId: 'savings',
        amount: 50,
      ),
    );

    expect(ledger.entries, hasLength(6));
    for (final projectionId in [
      'expense-flow',
      'income-flow',
      'transfer-flow',
    ]) {
      _expectBalanced(
        ledger.entries
            .where((entry) => entry.transactionId == projectionId)
            .toList(),
      );
    }
    expect(
      ledger.entries
          .singleWhere((entry) => entry.accountId == 'ledger-food')
          .purpose,
      LedgerPurpose.expense,
    );
    expect(
      ledger.entries
          .singleWhere((entry) => entry.accountId == 'ledger-salary')
          .purpose,
      LedgerPurpose.income,
    );
  });

  test(
    'credit card purchase counts as expense while card side remains debt',
    () async {
      final ledger = _MemoryLedgerPort();
      final categoryMapper = CategoryLedgerMapper(
        lookup: (categoryId) => LedgerAccount(
          id: 'ledger-$categoryId',
          name: 'Food expense',
          type: LedgerAccountType.expense,
          categoryId: categoryId,
          isSystem: true,
        ),
      );
      final service = LedgerProjectionService(
        ledgerPort: ledger,
        categoryMapper: categoryMapper,
      );

      await service.projectRecord(
        _record(
          id: 'card-charge',
          type: TransactionType.creditCardCharge,
          toAccountId: 'credit-card',
          categoryId: 'food',
          amount: 125,
        ),
      );

      _expectBalanced(ledger.entries);
      final expenseEntry = ledger.entries.singleWhere(
        (entry) => entry.accountId == 'ledger-food',
      );
      final liabilityEntry = ledger.entries.singleWhere(
        (entry) => entry.accountId == 'credit-card',
      );
      expect(expenseEntry.entryType, EntryType.debit);
      expect(expenseEntry.purpose, LedgerPurpose.expense);
      expect(liabilityEntry.entryType, EntryType.credit);
      expect(liabilityEntry.purpose, LedgerPurpose.debt);
    },
  );

  test(
    'category mapping to a non-system expense account is rejected',
    () async {
      final ledger = _MemoryLedgerPort();
      final categoryMapper = CategoryLedgerMapper(
        lookup: (categoryId) => LedgerAccount(
          id: 'user-expense-account',
          name: 'User account',
          type: LedgerAccountType.expense,
          categoryId: categoryId,
          isSystem: false,
        ),
      );
      final service = LedgerProjectionService(
        ledgerPort: ledger,
        categoryMapper: categoryMapper,
      );

      await expectLater(
        service.projectRecord(
          _record(
            id: 'expense-non-system-map',
            type: TransactionType.expense,
            fromAccountId: 'wallet',
            categoryId: 'food',
            amount: 10,
          ),
        ),
        throwsA(isA<InvalidCategoryLedgerMappingException>()),
      );
      expect(ledger.entries, isEmpty);
    },
  );

  test('expense category mapped to income account is rejected', () async {
    final ledger = _MemoryLedgerPort();
    final categoryMapper = CategoryLedgerMapper(
      lookup: (categoryId) => LedgerAccount(
        id: 'wrong-ledger-account',
        name: 'Wrong type',
        type: LedgerAccountType.income,
        categoryId: categoryId,
        isSystem: true,
      ),
    );
    final service = LedgerProjectionService(
      ledgerPort: ledger,
      categoryMapper: categoryMapper,
    );

    await expectLater(
      service.projectRecord(
        _record(
          id: 'expense-wrong-map',
          type: TransactionType.expense,
          fromAccountId: 'wallet',
          categoryId: 'food',
          amount: 10,
        ),
      ),
      throwsA(isA<InvalidCategoryLedgerMappingException>()),
    );
    expect(ledger.entries, isEmpty);
  });
}

FinancialTransactionRecord _record({
  required String id,
  required String type,
  String? fromAccountId,
  String? toAccountId,
  String? categoryId,
  required double amount,
}) {
  return FinancialTransactionRecord(
    transactionId: id,
    type: type,
    fromAccountId: fromAccountId,
    toAccountId: toAccountId,
    categoryId: categoryId,
    amount: Money.fromDouble(amount),
    currencyCode: 'EGP',
    paymentMethod: 'cash',
    occurredAt: DateTime(2026, 1, 1),
    isExceptional: false,
    source: 'manual',
  );
}

final class _MemoryLedgerPort implements LedgerPort {
  final List<LedgerEntry> entries = [];

  @override
  Future<void> createEntries(List<LedgerEntry> newEntries) async {
    entries.addAll(newEntries);
  }

  @override
  Future<List<LedgerEntry>> getEntriesByTransactionId(
    String transactionId,
  ) async {
    return entries
        .where((entry) => entry.transactionId == transactionId)
        .toList(growable: false);
  }

  @override
  Future<void> deleteEntriesByTransactionId(String transactionId) async {
    entries.removeWhere((entry) => entry.transactionId == transactionId);
  }
}

void _expectBalanced(List<LedgerEntry> entries) {
  final debitTotal = entries
      .where((entry) => entry.entryType == EntryType.debit)
      .fold<double>(0, (total, entry) => total + entry.amount);
  final creditTotal = entries
      .where((entry) => entry.entryType == EntryType.credit)
      .fold<double>(0, (total, entry) => total + entry.amount);
  expect(debitTotal, closeTo(creditTotal, 0.000001));
}
