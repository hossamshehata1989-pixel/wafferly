import 'package:hive/hive.dart';

import '../../core/money/money.dart';
import '../domain/financial_correction_record.dart';
import '../domain/financial_transaction_record.dart';
import '../ports/correction_port.dart';

final class HiveCorrectionPort implements CorrectionPort {
  final Box<Map> _box;

  const HiveCorrectionPort(this._box);

  @override
  Future<void> save(FinancialCorrectionRecord record) async {
    await _box.put(record.correctionId, {
      'correctionId': record.correctionId,
      'originalTransactionId': record.originalTransactionId,
      'before': _encode(record.before),
      'after': _encode(record.after),
    });
  }

  @override
  Future<FinancialCorrectionRecord?> findById(String correctionId) async {
    final value = _box.get(correctionId);
    if (value == null) return null;

    return FinancialCorrectionRecord(
      correctionId: value['correctionId'] as String,
      originalTransactionId: value['originalTransactionId'] as String,
      before: decodeTransaction(value['before'] as Map),
      after: decodeTransaction(value['after'] as Map),
    );
  }

  @override
  Future<void> delete(String correctionId) async {
    await _box.delete(correctionId);
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

  static FinancialTransactionRecord decodeTransaction(Map value) {
    return FinancialTransactionRecord(
      transactionId: value['transactionId'] as String,
      type: value['type'] as String,
      fromAccountId: value['fromAccountId'] as String?,
      toAccountId: value['toAccountId'] as String?,
      categoryId: value['categoryId'] as String?,
      subCategoryId: value['subCategoryId'] as String?,
      amount: Money.fromDouble((value['amount'] as num).toDouble()),
      currencyCode: value['currencyCode'] as String,
      paymentMethod: value['paymentMethod'] as String,
      occurredAt: DateTime.parse(value['occurredAt'] as String),
      note: value['note'] as String?,
      isExceptional: value['isExceptional'] as bool? ?? false,
      source: value['source'] as String,
      actorMemberId: value['actorMemberId'] as String?,
      commitmentId: value['commitmentId'] as String?,
      scheduleRuleId: value['scheduleRuleId'] as String?,
      occurrenceId: value['occurrenceId'] as String?,
    );
  }
}
