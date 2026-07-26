import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../models/transaction.dart';
import '../domain/financial_transaction_record.dart';
import '../ports/transaction_port.dart';
import '../ports/transaction_lookup_port.dart';
import '../ports/transaction_update_port.dart';

final class HiveTransactionPort
    implements TransactionPort, TransactionLookupPort, TransactionUpdatePort {
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

  @override
  Future<FinancialTransactionRecord?> findById(String transactionId) async {
    final transaction = _box.get(transactionId);

    if (transaction == null) {
      return null;
    }

    return FinancialTransactionRecord(
      transactionId: transaction.id,
      type: transaction.type,
      fromAccountId: transaction.fromAccountId,
      toAccountId: transaction.toAccountId,
      categoryId: transaction.categoryId,
      subCategoryId: transaction.subCategoryId,
      amount: transaction.amount,
      currencyCode: transaction.currencyCode,
      paymentMethod: transaction.paymentMethod,
      occurredAt: transaction.date,
      note: transaction.note,
      isExceptional: transaction.isExceptional,
      source: transaction.source,
      actorMemberId: transaction.actorMemberId,
    );
  }

  @override
  Future<void> update(
    FinancialTransactionRecord before,
    FinancialTransactionRecord after,
  ) async {
    debugPrint('================ UPDATE START ================');
    debugPrint('before.id = ${before.transactionId}');
    debugPrint('after.id  = ${after.transactionId}');
    debugPrint('ids match = ${before.transactionId == after.transactionId}');
    debugPrint('box length before = ${_box.length}');
    debugPrint('contains before = ${_box.containsKey(before.transactionId)}');
    debugPrint('contains after  = ${_box.containsKey(after.transactionId)}');

    final existing = _box.get(before.transactionId);

    if (existing == null) {
      throw StateError('Transaction not found: ${before.transactionId}');
    }

    final updated = Transaction(
      id: after.transactionId,
      amount: after.amount,
      type: after.type,
      fromAccountId: after.fromAccountId,
      toAccountId: after.toAccountId,
      categoryId: after.categoryId,
      subCategoryId: after.subCategoryId,
      date: after.occurredAt,
      note: after.note,
      paymentMethod: after.paymentMethod,
      isExceptional: after.isExceptional,
      currencyCode: after.currencyCode,
      source: after.source,
      actorMemberId: after.actorMemberId,
    );

    debugPrint('writing key = ${updated.id}');

    await _box.put(updated.id, updated);

    debugPrint('box length after = ${_box.length}');
    debugPrint('================ UPDATE END ==================');
  }
}
