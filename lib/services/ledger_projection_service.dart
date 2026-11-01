import '../constants/ledger_system_account_ids.dart';
import '../constants/transaction_constants.dart';
import '../core/money/money.dart';
import '../financial_engine/domain/financial_correction_record.dart';
import '../financial_engine/domain/financial_invalidation_record.dart';
import '../financial_engine/domain/financial_transaction_record.dart';
import '../infrastructure/ports/hive_ledger_port.dart';
import '../models/enums/entry_type.dart';
import '../models/enums/ledger_account_type.dart';
import '../models/ledger_entry.dart';
import '../models/transaction.dart';
import '../ports/ledger_port.dart';
import 'category_ledger_mapper.dart';
import 'ledger_projection_exceptions.dart';
import 'transaction_ledger_builder.dart';

/// Coordinates the persistent Ledger projection defined by ADR-0016.
///
/// FinancialTransactionRecord remains the financial write model. Journal
/// mutations remain accounting intent; this service projects the write model
/// through TransactionLedgerBuilder and persists it through LedgerPort.
class LedgerProjectionService {
  final CategoryLedgerMapper _categoryMapper;
  final TransactionLedgerBuilder _builder;
  final LedgerPort _ledgerPort;

  LedgerProjectionService({
    LedgerPort? ledgerPort,
    CategoryLedgerMapper? categoryMapper,
    TransactionLedgerBuilder? builder,
  }) : _ledgerPort = ledgerPort ?? HiveLedgerPort(),
       _categoryMapper = categoryMapper ?? CategoryLedgerMapper(),
       _builder = builder ?? TransactionLedgerBuilder();

  /// Projects one Financial Engine transaction as exactly two Ledger entries.
  Future<void> projectRecord(FinancialTransactionRecord record) async {
    if (await _alreadyProjected(record.transactionId, expectedEntryCount: 2)) {
      return;
    }

    final entries = _buildEntriesFromRecord(record);
    await _persistEntries(entries);
  }

  /// Projects a correction as two reversal entries plus two corrected entries.
  Future<void> projectCorrection(FinancialCorrectionRecord correction) async {
    if (await _alreadyProjected(
      correction.correctionId,
      expectedEntryCount: 4,
    )) {
      return;
    }

    final reversalEntries = _buildCorrectionReversalEntries(correction);
    final correctedEntries = _buildEntriesFromRecord(
      correction.after,
      projectionId: correction.correctionId,
    );

    if (reversalEntries.length != 2 || correctedEntries.length != 2) {
      throw StateError(
        'Correction projection must contain exactly four entries '
        '(${correction.correctionId}).',
      );
    }

    await _persistEntries([...reversalEntries, ...correctedEntries]);
  }

  /// Projects an invalidation as two entries reversing the original truth.
  Future<void> projectInvalidation(
    FinancialInvalidationRecord invalidation,
  ) async {
    if (await _alreadyProjected(
      invalidation.invalidationId,
      expectedEntryCount: 2,
    )) {
      return;
    }

    final reversalEntries = _buildInvalidationReversalEntries(invalidation);
    if (reversalEntries.length != 2) {
      throw StateError(
        'Invalidation projection must contain exactly two entries '
        '(${invalidation.invalidationId}).',
      );
    }

    await _persistEntries(reversalEntries);
  }

  Future<void> deleteProjection(String projectionId) {
    return _ledgerPort.deleteEntriesByTransactionId(projectionId);
  }

  // -------------------------------------------------------------------------
  // Legacy compatibility API
  // -------------------------------------------------------------------------

  /// Compatibility API for the legacy TransactionService path.
  /// Keep until the legacy Ledger-writing path is fully removed and verified.
  Future<void> project(Transaction transaction) async {
    if (await _alreadyProjected(transaction.id, expectedEntryCount: 2)) {
      return;
    }

    await _persistEntries(_buildEntries(transaction));
  }

  List<LedgerEntry> _buildEntries(Transaction transaction) {
    switch (transaction.type) {
      case TransactionType.expense:
        return _buildExpenseEntries(transaction);
      case TransactionType.income:
        return _buildIncomeEntries(transaction);
      case TransactionType.transfer:
        return _buildTransferEntries(transaction);
      case TransactionType.creditCardCharge:
        return _buildCreditCardChargeEntries(transaction);
      case TransactionType.initialBalance:
        return _buildOpeningBalanceEntries(transaction);
      case TransactionType.balanceReconciliation:
        return _buildBalanceReconciliationEntries(transaction);
      default:
        throw UnsupportedLedgerTransactionTypeException(transaction.type);
    }
  }

  List<LedgerEntry> _buildTransferEntries(Transaction transaction) {
    final fromAccountId = transaction.fromAccountId;
    final toAccountId = transaction.toAccountId;
    if (fromAccountId == null || toAccountId == null) {
      throw StateError(
        'Transfer transaction must define fromAccountId and toAccountId.',
      );
    }

    return _builder.buildTransferEntries(
      transactionId: transaction.id,
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      amount: Money.fromDouble(transaction.amount),
      date: transaction.date,
    );
  }

  List<LedgerEntry> _buildExpenseEntries(Transaction transaction) {
    final sourceAccountId = transaction.fromAccountId;
    final categoryId = transaction.categoryId;
    if (sourceAccountId == null || categoryId == null) {
      throw StateError(
        'Expense transaction must define source account and category.',
      );
    }

    final expenseLedgerId = _requireCategoryLedgerAccountId(
      categoryId: categoryId,
      expectedType: LedgerAccountType.expense,
    );
    return _builder.buildExpenseEntries(
      transactionId: transaction.id,
      expenseLedgerAccountId: expenseLedgerId,
      sourceAccountId: sourceAccountId,
      amount: Money.fromDouble(transaction.amount),
      date: transaction.date,
    );
  }

  List<LedgerEntry> _buildIncomeEntries(Transaction transaction) {
    final destinationAccountId = transaction.toAccountId;
    final categoryId = transaction.categoryId;
    if (destinationAccountId == null || categoryId == null) {
      throw StateError(
        'Income transaction must define destination account and category.',
      );
    }

    final incomeLedgerId = _requireCategoryLedgerAccountId(
      categoryId: categoryId,
      expectedType: LedgerAccountType.income,
    );
    return _builder.buildIncomeEntries(
      transactionId: transaction.id,
      destinationAccountId: destinationAccountId,
      incomeLedgerAccountId: incomeLedgerId,
      amount: Money.fromDouble(transaction.amount),
      date: transaction.date,
    );
  }

  List<LedgerEntry> _buildCreditCardChargeEntries(Transaction transaction) {
    final liabilityAccountId = transaction.toAccountId;
    final categoryId = transaction.categoryId;
    if (liabilityAccountId == null || categoryId == null) {
      throw StateError(
        'Credit Card charge must define liability account and expense category.',
      );
    }

    final expenseLedgerId = _requireCategoryLedgerAccountId(
      categoryId: categoryId,
      expectedType: LedgerAccountType.expense,
    );
    return _builder.buildCreditCardChargeEntries(
      transactionId: transaction.id,
      expenseLedgerAccountId: expenseLedgerId,
      liabilityAccountId: liabilityAccountId,
      amount: Money.fromDouble(transaction.amount),
      date: transaction.date,
    );
  }

  List<LedgerEntry> _buildOpeningBalanceEntries(Transaction transaction) {
    if ((transaction.fromAccountId == null) ==
        (transaction.toAccountId == null)) {
      throw StateError('Opening balance must define exactly one account side.');
    }

    return _builder.buildOpeningBalanceEntries(
      transactionId: transaction.id,
      accountId: transaction.toAccountId ?? transaction.fromAccountId!,
      accountReceivesDebit: transaction.toAccountId != null,
      amount: Money.fromDouble(transaction.amount),
      date: transaction.date,
    );
  }

  List<LedgerEntry> _buildBalanceReconciliationEntries(
    Transaction transaction,
  ) {
    final fromAccountId = transaction.fromAccountId;
    final toAccountId = transaction.toAccountId;
    if (fromAccountId == null || toAccountId == null) {
      throw StateError(
        'Balance reconciliation must define credit and debit accounts.',
      );
    }
    final fromIsEquity =
        fromAccountId == LedgerSystemAccountIds.balanceReconciliationEquity;
    final toIsEquity =
        toAccountId == LedgerSystemAccountIds.balanceReconciliationEquity;
    if (fromIsEquity == toIsEquity) {
      throw StateError(
        'Balance reconciliation must use the canonical reconciliation equity account on exactly one side.',
      );
    }

    return _builder.buildBalanceReconciliationEntries(
      transactionId: transaction.id,
      debitAccountId: toAccountId,
      creditAccountId: fromAccountId,
      amount: Money.fromDouble(transaction.amount),
      date: transaction.date,
    );
  }

  // -------------------------------------------------------------------------
  // Financial Engine write-model builders
  // -------------------------------------------------------------------------

  List<LedgerEntry> _buildEntriesFromRecord(
    FinancialTransactionRecord record, {
    String? projectionId,
  }) {
    switch (record.type) {
      case TransactionType.expense:
        return _buildExpenseEntriesFromRecord(
          record,
          projectionId: projectionId,
        );
      case TransactionType.income:
        return _buildIncomeEntriesFromRecord(
          record,
          projectionId: projectionId,
        );
      case TransactionType.transfer:
        return _buildTransferEntriesFromRecord(
          record,
          projectionId: projectionId,
        );
      case TransactionType.creditCardCharge:
        return _buildCreditCardChargeEntriesFromRecord(
          record,
          projectionId: projectionId,
        );
      case TransactionType.balanceReconciliation:
        return _buildBalanceReconciliationEntriesFromRecord(
          record,
          projectionId: projectionId,
        );
      case TransactionType.initialBalance:
        return _buildOpeningBalanceEntriesFromRecord(
          record,
          projectionId: projectionId,
        );
      default:
        throw UnsupportedLedgerTransactionTypeException(record.type);
    }
  }

  List<LedgerEntry> _buildExpenseEntriesFromRecord(
    FinancialTransactionRecord record, {
    String? projectionId,
  }) {
    final sourceAccountId = record.fromAccountId;
    final categoryId = record.categoryId;
    if (sourceAccountId == null || categoryId == null) {
      throw StateError(
        'Expense record must define source account and category.',
      );
    }

    final expenseLedgerId = _requireCategoryLedgerAccountId(
      categoryId: categoryId,
      expectedType: LedgerAccountType.expense,
    );
    return _builder.buildExpenseEntries(
      transactionId: projectionId ?? record.transactionId,
      expenseLedgerAccountId: expenseLedgerId,
      sourceAccountId: sourceAccountId,
      amount: record.amount,
      date: record.occurredAt,
    );
  }

  List<LedgerEntry> _buildIncomeEntriesFromRecord(
    FinancialTransactionRecord record, {
    String? projectionId,
  }) {
    final destinationAccountId = record.toAccountId;
    final categoryId = record.categoryId;
    if (destinationAccountId == null || categoryId == null) {
      throw StateError(
        'Income record must define destination account and category.',
      );
    }

    final incomeLedgerId = _requireCategoryLedgerAccountId(
      categoryId: categoryId,
      expectedType: LedgerAccountType.income,
    );
    return _builder.buildIncomeEntries(
      transactionId: projectionId ?? record.transactionId,
      destinationAccountId: destinationAccountId,
      incomeLedgerAccountId: incomeLedgerId,
      amount: record.amount,
      date: record.occurredAt,
    );
  }

  List<LedgerEntry> _buildCreditCardChargeEntriesFromRecord(
    FinancialTransactionRecord record, {
    String? projectionId,
  }) {
    final liabilityAccountId = record.toAccountId;
    final categoryId = record.categoryId;
    if (liabilityAccountId == null || categoryId == null) {
      throw StateError(
        'Credit Card charge must define liability account and expense category.',
      );
    }

    final expenseLedgerId = _requireCategoryLedgerAccountId(
      categoryId: categoryId,
      expectedType: LedgerAccountType.expense,
    );
    return _builder.buildCreditCardChargeEntries(
      transactionId: projectionId ?? record.transactionId,
      expenseLedgerAccountId: expenseLedgerId,
      liabilityAccountId: liabilityAccountId,
      amount: record.amount,
      date: record.occurredAt,
    );
  }

  List<LedgerEntry> _buildTransferEntriesFromRecord(
    FinancialTransactionRecord record, {
    String? projectionId,
  }) {
    final fromAccountId = record.fromAccountId;
    final toAccountId = record.toAccountId;
    if (fromAccountId == null || toAccountId == null) {
      throw StateError(
        'Transfer record must define fromAccountId and toAccountId.',
      );
    }

    return _builder.buildTransferEntries(
      transactionId: projectionId ?? record.transactionId,
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      amount: record.amount,
      date: record.occurredAt,
    );
  }

  List<LedgerEntry> _buildOpeningBalanceEntriesFromRecord(
    FinancialTransactionRecord record, {
    String? projectionId,
  }) {
    if ((record.fromAccountId == null) == (record.toAccountId == null)) {
      throw StateError(
        'Opening balance record must define exactly one account side.',
      );
    }

    return _builder.buildOpeningBalanceEntries(
      transactionId: projectionId ?? record.transactionId,
      accountId: record.toAccountId ?? record.fromAccountId!,
      accountReceivesDebit: record.toAccountId != null,
      amount: record.amount,
      date: record.occurredAt,
    );
  }

  List<LedgerEntry> _buildBalanceReconciliationEntriesFromRecord(
    FinancialTransactionRecord record, {
    String? projectionId,
  }) {
    final creditAccountId = record.fromAccountId;
    final debitAccountId = record.toAccountId;
    if (creditAccountId == null || debitAccountId == null) {
      throw StateError(
        'Balance reconciliation record must define credit/debit accounts.',
      );
    }
    final creditIsEquity =
        creditAccountId == LedgerSystemAccountIds.balanceReconciliationEquity;
    final debitIsEquity =
        debitAccountId == LedgerSystemAccountIds.balanceReconciliationEquity;
    if (creditIsEquity == debitIsEquity) {
      throw StateError(
        'Balance reconciliation must use the canonical reconciliation equity account on exactly one side.',
      );
    }

    return _builder.buildBalanceReconciliationEntries(
      transactionId: projectionId ?? record.transactionId,
      debitAccountId: debitAccountId,
      creditAccountId: creditAccountId,
      amount: record.amount,
      date: record.occurredAt,
    );
  }

  List<LedgerEntry> _buildInvalidationReversalEntries(
    FinancialInvalidationRecord invalidation,
  ) {
    final before = invalidation.before;
    final mappedAccountIds = _resolveReversalCategoryAccounts(before);

    return _builder.buildInvalidationReversalEntries(
      invalidationId: invalidation.invalidationId,
      originalTransactionId: invalidation.originalTransactionId,
      type: before.type,
      expenseLedgerAccountId: mappedAccountIds.$1,
      incomeLedgerAccountId: mappedAccountIds.$2,
      fromAccountId: before.fromAccountId,
      toAccountId: before.toAccountId,
      amount: before.amount,
      date: before.occurredAt,
    );
  }

  List<LedgerEntry> _buildCorrectionReversalEntries(
    FinancialCorrectionRecord correction,
  ) {
    final before = correction.before;
    final mappedAccountIds = _resolveReversalCategoryAccounts(before);

    return _builder.buildCorrectionReversalEntries(
      correctionId: correction.correctionId,
      originalTransactionId: correction.originalTransactionId,
      type: before.type,
      expenseLedgerAccountId: mappedAccountIds.$1,
      incomeLedgerAccountId: mappedAccountIds.$2,
      fromAccountId: before.fromAccountId,
      toAccountId: before.toAccountId,
      amount: before.amount,
      date: before.occurredAt,
    );
  }

  (String?, String?) _resolveReversalCategoryAccounts(
    FinancialTransactionRecord record,
  ) {
    switch (record.type) {
      case TransactionType.expense:
      case TransactionType.creditCardCharge:
        final categoryId = record.categoryId;
        if (categoryId == null || categoryId.trim().isEmpty) {
          throw StateError(
            'A ${record.type} reversal must retain its original category ID.',
          );
        }
        return (
          _requireCategoryLedgerAccountId(
            categoryId: categoryId,
            expectedType: LedgerAccountType.expense,
          ),
          null,
        );
      case TransactionType.income:
        final categoryId = record.categoryId;
        if (categoryId == null || categoryId.trim().isEmpty) {
          throw StateError(
            'An income reversal must retain its original category ID.',
          );
        }
        return (
          null,
          _requireCategoryLedgerAccountId(
            categoryId: categoryId,
            expectedType: LedgerAccountType.income,
          ),
        );
      case TransactionType.balanceReconciliation:
        final fromIsEquity =
            record.fromAccountId ==
            LedgerSystemAccountIds.balanceReconciliationEquity;
        final toIsEquity =
            record.toAccountId ==
            LedgerSystemAccountIds.balanceReconciliationEquity;
        if (fromIsEquity == toIsEquity) {
          throw StateError(
            'Balance reconciliation reversal must use the canonical equity account on exactly one side.',
          );
        }
        return (null, null);
      default:
        return (null, null);
    }
  }

  String _requireCategoryLedgerAccountId({
    required String categoryId,
    required LedgerAccountType expectedType,
  }) {
    final accountId = _categoryMapper.getLedgerAccountIdForCategory(
      categoryId,
      expectedType: expectedType,
    );
    if (accountId == null) {
      throw MissingCategoryLedgerMappingException(
        categoryId: categoryId,
        expectedType: expectedType,
      );
    }
    return accountId;
  }

  Future<void> _persistEntries(List<LedgerEntry> entries) async {
    _validateProjectionBatch(entries);
    await _ledgerPort.createEntries(entries);
  }

  void _validateProjectionBatch(List<LedgerEntry> entries) {
    if (entries.length != 2 && entries.length != 4) {
      throw StateError(
        'Ledger projection must contain two or four entries; '
        'received ${entries.length}.',
      );
    }

    var debitTotal = 0.0;
    var creditTotal = 0.0;
    var debitCount = 0;
    var creditCount = 0;
    for (final entry in entries) {
      if (entry.accountId.trim().isEmpty) {
        throw StateError(
          'Ledger projection contains an empty account ID for entry "${entry.id}".',
        );
      }
      if (!entry.amount.isFinite || entry.amount < 0) {
        throw StateError(
          'Ledger projection contains an invalid amount for entry "${entry.id}".',
        );
      }
      switch (entry.entryType) {
        case EntryType.debit:
          debitTotal += entry.amount;
          debitCount++;
          break;
        case EntryType.credit:
          creditTotal += entry.amount;
          creditCount++;
          break;
      }
    }

    if (debitCount == 0 || creditCount == 0 || debitCount != creditCount) {
      throw StateError(
        'Ledger projection must contain matching debit and credit lines.',
      );
    }

    if ((debitTotal - creditTotal).abs() > 0.000001) {
      throw StateError(
        'Unbalanced Ledger projection: debit $debitTotal, '
        'credit $creditTotal.',
      );
    }
  }

  Future<bool> _alreadyProjected(
    String projectionId, {
    required int expectedEntryCount,
  }) async {
    final existing = await _ledgerPort.getEntriesByTransactionId(projectionId);
    if (existing.isEmpty) return false;
    if (existing.length != expectedEntryCount) {
      throw StateError(
        'Incomplete Ledger projection "$projectionId": '
        '${existing.length} entries found, expected $expectedEntryCount.',
      );
    }
    _validateProjectionBatch(existing);
    return true;
  }
}
