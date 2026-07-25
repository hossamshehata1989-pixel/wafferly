import '../../models/transaction.dart';
import '../domain/financial_transaction_record.dart';

final class TransactionRecordMapper {
  const TransactionRecordMapper();

  FinancialTransactionRecord fromTransaction(Transaction transaction) {
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
}
