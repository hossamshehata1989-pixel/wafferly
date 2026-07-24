import '../constants/transaction_constants.dart';
import '../models/ledger_entry.dart';
import '../models/transaction.dart';
import 'category_ledger_mapper.dart';
import '../ports/ledger_port.dart';
import '../infrastructure/ports/hive_ledger_port.dart';
import 'transaction_ledger_builder.dart';

/// مسؤول عن إنشاء الـ Ledger Projection من Transaction.
///
/// هذه الخدمة لا تحفظ Transaction.
/// ولا تحتوي على CRUD.
/// ولا تُستدعى إلا بعد نجاح حفظ Transaction.
class LedgerProjectionService {
  final CategoryLedgerMapper _categoryMapper = CategoryLedgerMapper();

  final TransactionLedgerBuilder _builder = TransactionLedgerBuilder();

  final LedgerPort _ledgerPort = HiveLedgerPort();

  Future<void> project(Transaction transaction) async {
    // ==============================
    // Idempotency
    // ==============================

    if (await _alreadyProjected(transaction.id)) {
      print(
        "ℹ️ Ledger entries already exist for transaction ${transaction.id} – skipping duplicate creation",
      );
      return;
    }

    final entries = _buildEntries(transaction);

    await _persistEntries(entries);
  }

  List<LedgerEntry> _buildTransferEntries(Transaction transaction) {
    if (transaction.fromAccountId == null || transaction.toAccountId == null) {
      throw Exception(
        "Transfer transaction missing fromAccountId or toAccountId",
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

  List<LedgerEntry> _buildExpenseEntries(Transaction transaction) {
    if (transaction.fromAccountId == null) {
      throw Exception("Expense transaction missing fromAccountId");
    }

    if (transaction.categoryId == null) {
      throw Exception("Expense transaction missing categoryId");
    }

    final expenseLedgerId = _categoryMapper.getLedgerAccountIdForCategory(
      transaction.categoryId!,
    );

    if (expenseLedgerId == null) {
      print(
        "⚠️ Missing LedgerAccount mapping for category: ${transaction.categoryId}",
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

  List<LedgerEntry> _buildIncomeEntries(Transaction transaction) {
    if (transaction.toAccountId == null) {
      throw Exception("Income transaction missing toAccountId");
    }

    if (transaction.categoryId == null) {
      throw Exception("Income transaction missing categoryId");
    }

    final incomeLedgerId = _categoryMapper.getLedgerAccountIdForCategory(
      transaction.categoryId!,
    );

    if (incomeLedgerId == null) {
      print(
        "⚠️ Missing LedgerAccount mapping for category: ${transaction.categoryId}",
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

  List<LedgerEntry> _buildEntries(Transaction transaction) {
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

  Future<void> _persistEntries(List<LedgerEntry> entries) async {
    if (entries.isEmpty) {
      return;
    }

    await _ledgerPort.createEntries(entries);
  }

  Future<bool> _alreadyProjected(String transactionId) async {
    final entries = await _ledgerPort.getEntriesByTransactionId(transactionId);

    return entries.isNotEmpty;
  }
}
