import '../constants/transaction_constants.dart';
import '../models/ledger_entry.dart';
import '../models/transaction.dart';
import '../financial_engine/domain/financial_transaction_record.dart';
import '../financial_engine/domain/financial_correction_record.dart';
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

  /// Projects an immutable financial correction as two effects under the
  /// correction write-model id:
  /// 1. neutralize the original truth;
  /// 2. establish the corrected truth.
  Future<void> projectCorrection(
    FinancialCorrectionRecord correction,
  ) async {
    if (await _alreadyProjected(correction.correctionId)) {
      return;
    }

    final reversalEntries = _buildCorrectionReversalEntries(correction);
    final correctedEntries = _buildEntriesFromRecord(
      correction.after,
      projectionId: correction.correctionId,
    );

    if (reversalEntries.isEmpty || correctedEntries.isEmpty) {
      throw StateError(
        'Correction projection cannot be empty for ${correction.correctionId}',
      );
    }

    await _persistEntries([
      ...reversalEntries,
      ...correctedEntries,
    ]);
  }

  Future<void> deleteProjection(String transactionId) async {
    await _ledgerPort.deleteEntriesByTransactionId(transactionId);
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
    FinancialTransactionRecord record, {
    String? projectionId,
  }) {
    if (record.fromAccountId == null ||
        record.toAccountId == null) {
      throw Exception(
        'Transfer transaction missing fromAccountId or toAccountId',
      );
    }

    return _builder.buildTransferEntries(
      transactionId: projectionId ?? record.transactionId,
      fromAccountId: record.fromAccountId!,
      toAccountId: record.toAccountId!,
      amount: record.amount.toDouble(),
      date: record.occurredAt,
    );
  }

  List<LedgerEntry> _buildExpenseEntriesFromRecord(
    FinancialTransactionRecord record, {
    String? projectionId,
  }) {
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
      transactionId: projectionId ?? record.transactionId,
      expenseLedgerAccountId: expenseLedgerId,
      sourceAccountId: record.fromAccountId!,
      amount: record.amount.toDouble(),
      date: record.occurredAt,
    );
  }

  List<LedgerEntry> _buildIncomeEntriesFromRecord(
    FinancialTransactionRecord record, {
    String? projectionId,
  }) {
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
      transactionId: projectionId ?? record.transactionId,
      destinationAccountId: record.toAccountId!,
      incomeLedgerAccountId: incomeLedgerId,
      amount: record.amount.toDouble(),
      date: record.occurredAt,
    );
  }

  List<LedgerEntry> _buildCorrectionReversalEntries(
    FinancialCorrectionRecord correction,
  ) {
    final before = correction.before;

    String? expenseLedgerId;
    String? incomeLedgerId;

    if (before.categoryId != null) {
      final mapped = _categoryMapper.getLedgerAccountIdForCategory(
        before.categoryId!,
      );
      if (before.type == TransactionType.expense) {
        expenseLedgerId = mapped;
      } else if (before.type == TransactionType.income) {
        incomeLedgerId = mapped;
      }
    }

    return _builder.buildCorrectionReversalEntries(
      correctionId: correction.correctionId,
      originalTransactionId: correction.originalTransactionId,
      type: before.type,
      expenseLedgerAccountId: expenseLedgerId,
      incomeLedgerAccountId: incomeLedgerId,
      fromAccountId: before.fromAccountId,
      toAccountId: before.toAccountId,
      amount: before.amount.toDouble(),
      date: before.occurredAt,
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