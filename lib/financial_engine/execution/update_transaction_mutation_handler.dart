import '../mutations/update_transaction_mutation.dart';
import '../ports/transaction_update_port.dart';
import 'financial_mutation_handler.dart';

final class UpdateTransactionMutationHandler
    implements FinancialMutationHandler<UpdateTransactionMutation> {
  final TransactionUpdatePort _port;

  const UpdateTransactionMutationHandler({required TransactionUpdatePort port})
    : _port = port;

  @override
  Future<void> execute(UpdateTransactionMutation mutation) {
    return _port.update(mutation.before, mutation.after);
  }
}
