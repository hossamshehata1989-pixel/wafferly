import '../constants/transaction_constants.dart';
import '../models/ledger_entry.dart';
import '../models/transaction.dart';
import 'category_ledger_mapper.dart';
import 'ledger_service.dart';
import 'transaction_ledger_builder.dart';

/// مسؤول عن إنشاء الـ Ledger Projection من Transaction.
///
/// هذه الخدمة لا تحفظ Transaction.
/// ولا تحتوي على CRUD.
/// ولا تُستدعى إلا بعد نجاح حفظ Transaction.
class LedgerProjectionService {
  final CategoryLedgerMapper _categoryMapper = CategoryLedgerMapper();

  final TransactionLedgerBuilder _builder = TransactionLedgerBuilder();

  final LedgerService _ledgerService = LedgerService();

  Future<void> project(Transaction transaction) async {
    // ==============================
    // Idempotency
    // ==============================

    final existingEntries = await _ledgerService.getEntriesByTransactionId(
      transaction.id,
    );

    if (existingEntries.isNotEmpty) {
      print(
        "ℹ️ Ledger entries already exist for transaction ${transaction.id} – skipping duplicate creation",
      );
      return;
    }

    List<LedgerEntry> entries = [];

    switch (transaction.type) {
      case TransactionType.transfer:
        entries = _buildTransferEntries(transaction);
        break;

      case TransactionType.expense:
        entries = _buildExpenseEntries(transaction);
        break;

      case TransactionType.income:
        entries = _buildIncomeEntries(transaction);
        break;

      default:
        print(
          "ℹ️ Ledger entries not created for transaction type: ${transaction.type}",
        );
        return;
    }

    if (entries.isNotEmpty) {
      await _ledgerService.createEntries(entries);
    }
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
}
