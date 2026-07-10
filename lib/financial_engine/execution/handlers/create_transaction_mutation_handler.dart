import '../../mutations/create_transaction_mutation.dart';
import '../../ports/transaction_port.dart';
import '../financial_mutation_handler.dart';

final class CreateTransactionMutationHandler
    implements FinancialMutationHandler<CreateTransactionMutation> {
  final TransactionPort _transactionPort;

  const CreateTransactionMutationHandler(this._transactionPort);

  @override
  Future<void> execute(CreateTransactionMutation mutation) {
    return _transactionPort.save(mutation.transaction);
  }
}
