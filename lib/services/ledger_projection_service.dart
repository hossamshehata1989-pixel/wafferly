import '../constants/transaction_constants.dart';
import '../models/ledger_entry.dart';
import '../models/transaction.dart';
import '../financial_engine/domain/financial_transaction_record.dart';
import 'category_ledger_mapper.dart';
import '../ports/ledger_port.dart';
import '../infrastructure/ports/hive_ledger_port.dart';
import 'transaction_ledger_builder.dart';

/// مسؤول عن إنشاء الـ Ledger Projection.
///
/// هذه الخدمة:
/// - لا تحفظ Transaction.
/// - لا تحتوي على CRUD.
/// - لا تحتوي على UI logic.
/// - مسؤولة فقط عن تنسيق عملية إنشاء الـ Ledger Projection.
/// - تتحقق من idempotency.
/// - تستدعي TransactionLedgerBuilder.
/// - تحفظ الناتج من خلال LedgerPort.
///
/// ADR-0016:
/// FinancialTransactionRecord هو Financial Write Model.
/// Ledger يتم إنشاؤه كـ Projection.
///
/// LedgerProjectionService هو الـ Orchestrator الوحيد
/// المسموح له باستدعاء TransactionLedgerBuilder.
class LedgerProjectionService {
  final CategoryLedgerMapper _categoryMapper = CategoryLedgerMapper();

  final TransactionLedgerBuilder _builder = TransactionLedgerBuilder();

  final LedgerPort _ledgerPort;

  LedgerProjectionService({
    LedgerPort? ledgerPort,
  }) : _ledgerPort = ledgerPort ?? HiveLedgerPort();

  // ============================================================
  // Financial Engine API
  // ============================================================

  /// Projects the Financial Engine write model into Ledger entries.
  ///
  /// This is the canonical API used by the Financial Engine.
  ///
  /// Flow:
  ///
  /// FinancialTransactionRecord
  ///        ↓
  /// LedgerProjectionService
  ///        ↓
  /// TransactionLedgerBuilder
  ///        ↓
  /// LedgerPort
  Future<void> projectRecord(
    FinancialTransactionRecord record,
  ) async {
    // ----------------------------------------------------------
    // Idempotency
    // ----------------------------------------------------------

    if (await _alreadyProjected(record.transactionId)) {
      print(
        'ℹ️ Ledger entries already exist for transaction '
        '${record.transactionId} – skipping duplicate creation',
      );
      return;
    }

    // ----------------------------------------------------------
    // Build Projection
    // ----------------------------------------------------------

    final entries = _buildEntriesFromRecord(record);

    // ----------------------------------------------------------
    // Persist Projection
    // ----------------------------------------------------------

    await _persistEntries(entries);
  }

  // ============================================================
  // Legacy Compatibility API
  // ============================================================

  /// Temporary compatibility API for the legacy TransactionService path.
  ///
  /// IMPORTANT:
  /// This method must remain until the legacy TransactionService
  /// Ledger-writing path is completely removed and verified.
  ///
  /// Do not remove during Step 1.
  Future<void> project(Transaction transaction) async {
    if (await _alreadyProjected(transaction.id)) {
      print(
        'ℹ️ Ledger entries already exist for transaction '
        '${transaction.id} – skipping duplicate creation',
      );
      return;
    }

    final entries = _buildEntries(transaction);

    await _persistEntries(entries);
  }

  // ============================================================
  // Legacy Transaction Builders
  // ============================================================

  List<LedgerEntry> _buildTransferEntries(
    Transaction transaction,
  ) {
    if (transaction.fromAccountId == null ||
        transaction.toAccountId == null) {
      throw Exception(
        'Transfer transaction missing fromAccountId or toAccountId',
      );
    }

    return _builder.buildTransferEntries(
      transactionId: transaction.id,
      fromAccountId: transaction.fromAccountId!,
      toAccountId: transaction.toAccountId!,
      amount: transaction.amount,
      date: transaction.date,
    );
  }

  List<LedgerEntry> _buildExpenseEntries(
    Transaction transaction,
  ) {
    if (transaction.fromAccountId == null) {
      throw Exception(
        'Expense transaction missing fromAccountId',
      );
    }

    if (transaction.categoryId == null) {
      throw Exception(
        'Expense transaction missing categoryId',
      );
    }

    final expenseLedgerId =
        _categoryMapper.getLedgerAccountIdForCategory(
      transaction.categoryId!,
    );

    if (expenseLedgerId == null) {
      print(
        '⚠️ Missing LedgerAccount mapping for category: '
        '${transaction.categoryId}',
      );
      return [];
    }

    return _builder.buildExpenseEntries(
      transactionId: transaction.id,
      expenseLedgerAccountId: expenseLedgerId,
      sourceAccountId: transaction.fromAccountId!,
      amount: transaction.amount,
      date: transaction.date,
    );
  }

  List<LedgerEntry> _buildIncomeEntries(
    Transaction transaction,
  ) {
    if (transaction.toAccountId == null) {
      throw Exception(
        'Income transaction missing toAccountId',
      );
    }

    if (transaction.categoryId == null) {
      throw Exception(
        'Income transaction missing categoryId',
      );
    }

    final incomeLedgerId =
        _categoryMapper.getLedgerAccountIdForCategory(
      transaction.categoryId!,
    );

    if (incomeLedgerId == null) {
      print(
        '⚠️ Missing LedgerAccount mapping for category: '
        '${transaction.categoryId}',
      );
      return [];
    }

    return _builder.buildIncomeEntries(
      transactionId: transaction.id,
      destinationAccountId: transaction.toAccountId!,
      incomeLedgerAccountId: incomeLedgerId,
      amount: transaction.amount,
      date: transaction.date,
    );
  }

  List<LedgerEntry> _buildEntries(
    Transaction transaction,
  ) {
    switch (transaction.type) {
      case TransactionType.expense:
        return _buildExpenseEntries(transaction);

      case TransactionType.income:
        return _buildIncomeEntries(transaction);

      case TransactionType.transfer:
        return _buildTransferEntries(transaction);

      default:
        return [];
    }
  }

  // ============================================================
  // FinancialTransactionRecord Builders
  // ============================================================

  List<LedgerEntry> _buildEntriesFromRecord(
    FinancialTransactionRecord record,
  ) {
    switch (record.type) {
      case TransactionType.expense:
        return _buildExpenseEntriesFromRecord(record);

      case TransactionType.income:
        return _buildIncomeEntriesFromRecord(record);

      case TransactionType.transfer:
        return _buildTransferEntriesFromRecord(record);

      default:
        // FinancialTransactionRecord may contain transaction
        // types that are not currently represented by the
        // LedgerProjectionService.
        //
        // Do not invent Ledger rules here.
        return [];
    }
  }

  List<LedgerEntry> _buildTransferEntriesFromRecord(
    FinancialTransactionRecord record,
  ) {
    if (record.fromAccountId == null ||
        record.toAccountId == null) {
      throw Exception(
        'Transfer transaction missing fromAccountId or toAccountId',
      );
    }

    return _builder.buildTransferEntries(
      transactionId: record.transactionId,
      fromAccountId: record.fromAccountId!,
      toAccountId: record.toAccountId!,
      amount: record.amount,
      date: record.occurredAt,
    );
  }

  List<LedgerEntry> _buildExpenseEntriesFromRecord(
    FinancialTransactionRecord record,
  ) {
    if (record.fromAccountId == null) {
      throw Exception(
        'Expense transaction missing fromAccountId',
      );
    }

    if (record.categoryId == null) {
      throw Exception(
        'Expense transaction missing categoryId',
      );
    }

    final expenseLedgerId =
        _categoryMapper.getLedgerAccountIdForCategory(
      record.categoryId!,
    );

    if (expenseLedgerId == null) {
      print(
        '⚠️ Missing LedgerAccount mapping for category: '
        '${record.categoryId}',
      );
      return [];
    }

    return _builder.buildExpenseEntries(
      transactionId: record.transactionId,
      expenseLedgerAccountId: expenseLedgerId,
      sourceAccountId: record.fromAccountId!,
      amount: record.amount,
      date: record.occurredAt,
    );
  }

  List<LedgerEntry> _buildIncomeEntriesFromRecord(
    FinancialTransactionRecord record,
  ) {
    if (record.toAccountId == null) {
      throw Exception(
        'Income transaction missing toAccountId',
      );
    }

    if (record.categoryId == null) {
      throw Exception(
        'Income transaction missing categoryId',
      );
    }

    final incomeLedgerId =
        _categoryMapper.getLedgerAccountIdForCategory(
      record.categoryId!,
    );

    if (incomeLedgerId == null) {
      print(
        '⚠️ Missing LedgerAccount mapping for category: '
        '${record.categoryId}',
      );
      return [];
    }

    return _builder.buildIncomeEntries(
      transactionId: record.transactionId,
      destinationAccountId: record.toAccountId!,
      incomeLedgerAccountId: incomeLedgerId,
      amount: record.amount,
      date: record.occurredAt,
    );
  }

  // ============================================================
  // Persistence
  // ============================================================

  Future<void> _persistEntries(
    List<LedgerEntry> entries,
  ) async {
    if (entries.isEmpty) {
      return;
    }

    await _ledgerPort.createEntries(entries);
  }

  // ============================================================
  // Idempotency
  // ============================================================

  Future<bool> _alreadyProjected(
    String transactionId,
  ) async {
    final entries =
        await _ledgerPort.getEntriesByTransactionId(
      transactionId,
    );

    return entries.isNotEmpty;
  }
}