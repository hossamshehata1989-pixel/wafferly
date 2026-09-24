// Sprint 3C — Category Ledger Mapping
// Updated to accept real ledgerAccountId instead of categoryId placeholder

import 'package:uuid/uuid.dart';
import '../models/ledger_entry.dart';
import '../models/enums/entry_type.dart';
import '../models/enums/ledger_purpose.dart';

class TransactionLedgerBuilder {
  final Uuid _uuid = const Uuid();

  LedgerEntry _createEntry({
    required String transactionId,
    required String accountId,
    required EntryType entryType,
    required double amount,
    required DateTime date,
    required LedgerPurpose purpose,
  }) {
    return LedgerEntry(
      id: _uuid.v4(),
      transactionId: transactionId,
      accountId: accountId,
      entryType: entryType,
      amount: amount,
      date: date,
      purpose: purpose,
    );
  }

  // ✅ Updated: accepts real expense ledger account ID
  List<LedgerEntry> buildExpenseEntries({
    required String transactionId,
    required String expenseLedgerAccountId, // real LedgerAccount.id
    required String sourceAccountId, // real Account.id (cash/bank)
    required double amount,
    required DateTime date,
  }) {
    return [
      _createEntry(
        transactionId: transactionId,
        accountId: expenseLedgerAccountId,
        entryType: EntryType.debit,
        amount: amount,
        date: date,
        purpose: LedgerPurpose.expense,
      ),
      _createEntry(
        transactionId: transactionId,
        accountId: sourceAccountId,
        entryType: EntryType.credit,
        amount: amount,
        date: date,
        purpose: LedgerPurpose.expense,
      ),
    ];
  }

  // ✅ Updated: accepts real income ledger account ID
  List<LedgerEntry> buildIncomeEntries({
    required String transactionId,
    required String destinationAccountId, // real Account.id (cash/bank)
    required String incomeLedgerAccountId, // real LedgerAccount.id
    required double amount,
    required DateTime date,
  }) {
    return [
      _createEntry(
        transactionId: transactionId,
        accountId: destinationAccountId,
        entryType: EntryType.debit,
        amount: amount,
        date: date,
        purpose: LedgerPurpose.income,
      ),
      _createEntry(
        transactionId: transactionId,
        accountId: incomeLedgerAccountId,
        entryType: EntryType.credit,
        amount: amount,
        date: date,
        purpose: LedgerPurpose.income,
      ),
    ];
  }

  // ✅ Transfer remains unchanged (uses real accounts)
  List<LedgerEntry> buildTransferEntries({
    required String transactionId,
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required DateTime date,
  }) {
    return [
      _createEntry(
        transactionId: transactionId,
        accountId: toAccountId,
        entryType: EntryType.debit,
        amount: amount,
        date: date,
        purpose: LedgerPurpose.transfer,
      ),
      _createEntry(
        transactionId: transactionId,
        accountId: fromAccountId,
        entryType: EntryType.credit,
        amount: amount,
        date: date,
        purpose: LedgerPurpose.transfer,
      ),
    ];
  }
  /// Builds the ledger effect that neutralizes a previously accepted
  /// transaction. A correction effect is not a synthetic Transaction; it is
  /// projected under the correction's own write-model id and marked as an
  /// adjustment.
  List<LedgerEntry> buildCorrectionReversalEntries({
    required String correctionId,
    required String originalTransactionId,
    required String type,
    required String? expenseLedgerAccountId,
    required String? incomeLedgerAccountId,
    required String? fromAccountId,
    required String? toAccountId,
    required double amount,
    required DateTime date,
  }) {
    List<LedgerEntry> original;

    switch (type) {
      case 'expense':
        if (fromAccountId == null || expenseLedgerAccountId == null) {
          throw StateError('Expense correction reversal is missing accounts');
        }
        original = buildExpenseEntries(
          transactionId: originalTransactionId,
          expenseLedgerAccountId: expenseLedgerAccountId,
          sourceAccountId: fromAccountId,
          amount: amount,
          date: date,
        );
        break;
      case 'income':
        if (toAccountId == null || incomeLedgerAccountId == null) {
          throw StateError('Income correction reversal is missing accounts');
        }
        original = buildIncomeEntries(
          transactionId: originalTransactionId,
          destinationAccountId: toAccountId,
          incomeLedgerAccountId: incomeLedgerAccountId,
          amount: amount,
          date: date,
        );
        break;
      case 'transfer':
        if (fromAccountId == null || toAccountId == null) {
          throw StateError('Transfer correction reversal is missing accounts');
        }
        original = buildTransferEntries(
          transactionId: originalTransactionId,
          fromAccountId: fromAccountId,
          toAccountId: toAccountId,
          amount: amount,
          date: date,
        );
        break;
      default:
        throw StateError('Unsupported correction type: $type');
    }

    return original
        .map(
          (entry) => LedgerEntry(
            id: _uuid.v4(),
            transactionId: correctionId,
            accountId: entry.accountId,
            entryType: entry.entryType == EntryType.debit
                ? EntryType.credit
                : EntryType.debit,
            amount: entry.amount,
            date: entry.date,
            purpose: LedgerPurpose.adjustment,
          ),
        )
        .toList();
  }

}
