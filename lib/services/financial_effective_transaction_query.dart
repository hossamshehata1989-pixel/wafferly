import 'package:hive/hive.dart';

import '../models/transaction.dart';

/// Read-side definition of the current/effective financial transaction truth.
///
/// Financial history is immutable: a correction does not delete the original
/// transaction. Instead, the correction records that the original transaction
/// has been superseded by a newer transaction. An invalidation records that a
/// transaction is no longer financially effective.
///
/// Therefore a transaction is effective only when:
///   1. it is present in the transaction store;
///   2. it has not been superseded by a correction; and
///   3. it has not been invalidated.
///
/// This is a read-side query only. It never mutates financial truth.
final class FinancialEffectiveTransactionQuery {
  const FinancialEffectiveTransactionQuery();

  Box<Transaction>? get _transactionsBox {
    if (!Hive.isBoxOpen('transactions')) return null;
    return Hive.box<Transaction>('transactions');
  }

  Box<Map>? get _correctionsBox {
    if (!Hive.isBoxOpen('financial_corrections')) return null;
    return Hive.box<Map>('financial_corrections');
  }

  Box<Map>? get _invalidationsBox {
    if (!Hive.isBoxOpen('financial_invalidations')) return null;
    return Hive.box<Map>('financial_invalidations');
  }

  Set<String> supersededTransactionIds() {
    final box = _correctionsBox;
    if (box == null) return <String>{};

    return box.values
        .map((value) => value['originalTransactionId'])
        .whereType<String>()
        .toSet();
  }

  Set<String> invalidatedTransactionIds() {
    final box = _invalidationsBox;
    if (box == null) return <String>{};

    return box.values
        .map((value) => value['originalTransactionId'])
        .whereType<String>()
        .toSet();
  }

  Set<String> inactiveTransactionIds() {
    return <String>{
      ...supersededTransactionIds(),
      ...invalidatedTransactionIds(),
    };
  }

  bool isEffective(String transactionId) {
    final box = _transactionsBox;
    if (box == null || box.get(transactionId) == null) return false;

    return !inactiveTransactionIds().contains(transactionId);
  }

  Transaction? getEffectiveById(String transactionId) {
    final box = _transactionsBox;
    if (box == null) return null;

    final transaction = box.get(transactionId);
    if (transaction == null) return null;

    return isEffective(transactionId) ? transaction : null;
  }

  List<Transaction> getEffectiveTransactions() {
    final box = _transactionsBox;
    if (box == null) return <Transaction>[];

    final inactive = inactiveTransactionIds();
    return box.values.where((tx) => !inactive.contains(tx.id)).toList();
  }
}
