import 'package:hive/hive.dart';

import '../domain/financial_invalidation_record.dart';
import '../domain/financial_transaction_record.dart';
import '../ports/invalidation_port.dart';
import 'hive_correction_port.dart';

final class HiveInvalidationPort implements InvalidationPort {
  final Box<Map> _box;

  const HiveInvalidationPort(this._box);

  @override
  Future<void> save(FinancialInvalidationRecord record) async {
    await _box.put(record.invalidationId, {
      'invalidationId': record.invalidationId,
      'originalTransactionId': record.originalTransactionId,
      'before': _encode(record.before),
    });
  }

  @override
  Future<FinancialInvalidationRecord?> findById(
    String invalidationId,
  ) async {
    final value = _box.get(invalidationId);
    if (value == null) return null;

    return FinancialInvalidationRecord(
      invalidationId: value['invalidationId'] as String,
      originalTransactionId: value['originalTransactionId'] as String,
      before: HiveCorrectionPort.decodeTransaction(value['before'] as Map),
    );
  }

  @override
  Future<FinancialInvalidationRecord?> findByOriginalTransactionId(
    String transactionId,
  ) async {
    for (final value in _box.values) {
      if (value['originalTransactionId'] == transactionId) {
        return FinancialInvalidationRecord(
          invalidationId: value['invalidationId'] as String,
          originalTransactionId: value['originalTransactionId'] as String,
          before: HiveCorrectionPort.decodeTransaction(
            value['before'] as Map,
          ),
        );
      }
    }
    return null;
  }

  @override
  Future<void> delete(String invalidationId) async {
    await _box.delete(invalidationId);
  }

  Map<String, dynamic> _encode(FinancialTransactionRecord record) {
    return {
      'transactionId': record.transactionId,
      'type': record.type,
      'fromAccountId': record.fromAccountId,
      'toAccountId': record.toAccountId,
      'categoryId': record.categoryId,
      'subCategoryId': record.subCategoryId,
      'amount': record.amount.toDouble(),
      'currencyCode': record.currencyCode,
      'paymentMethod': record.paymentMethod,
      'occurredAt': record.occurredAt.toIso8601String(),
      'note': record.note,
      'isExceptional': record.isExceptional,
      'source': record.source,
      'actorMemberId': record.actorMemberId,
      'commitmentId': record.commitmentId,
      'scheduleRuleId': record.scheduleRuleId,
      'occurrenceId': record.occurrenceId,
    };
  }
}
