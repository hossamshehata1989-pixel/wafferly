import '../../../models/transaction.dart';

final class DeleteTransactionIntent {
  final Transaction transaction;

  const DeleteTransactionIntent({required this.transaction});
}
