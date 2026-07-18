import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../models/transaction.dart';
import '../domain/financial_transaction_record.dart';
import '../ports/transaction_port.dart';

final class HiveTransactionPort implements TransactionPort {
  final Box<Transaction> _box;

  const HiveTransactionPort(this._box);

  @override
  Future<void> save(FinancialTransactionRecord record) async {
    debugPrint('TX PORT: save() called');

    final transaction = Transaction(
      id: record.transactionId,
      amount: record.amount,
      type: record.type,
      fromAccountId: record.fromAccountId,
      toAccountId: record.toAccountId,
      categoryId: record.categoryId,
      date: record.occurredAt,
      note: record.note,
      paymentMethod: record.paymentMethod,
      isExceptional: record.isExceptional,
      subCategoryId: record.subCategoryId,
      currencyCode: record.currencyCode,
      source: record.source,
      actorMemberId: record.actorMemberId,
    );

    await _box.put(transaction.id, transaction);

    debugPrint('TX PORT: Saved ${transaction.id} (box count = ${_box.length})');
  }
}
