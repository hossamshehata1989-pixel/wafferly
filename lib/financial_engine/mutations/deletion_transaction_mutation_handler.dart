import '../ports/transaction_port.dart';
import 'deletion_transaction_mutation.dart';
import '../execution/financial_mutation_handler.dart';

final class DeleteTransactionMutationHandler
    implements FinancialMutationHandler<DeleteTransactionMutation> {
  final TransactionPort _transactionPort;

  const DeleteTransactionMutationHandler({
    required TransactionPort transactionPort,
  }) : _transactionPort = transactionPort;

  @override
  Future<void> execute(DeleteTransactionMutation mutation) async {
    await _transactionPort.delete(mutation.record.transactionId);
  }
}
