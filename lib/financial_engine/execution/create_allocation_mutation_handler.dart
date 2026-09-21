import '../operations/create_allocation_mutation.dart';
import '../ports/create_allocation_port.dart';
import 'financial_mutation_handler.dart';
import 'financial_transaction_context.dart';

final class CreateAllocationMutationHandler
    implements FinancialMutationHandler<CreateAllocationMutation> {
  final CreateAllocationPort _port;

  const CreateAllocationMutationHandler({
    required CreateAllocationPort port,
  }) : _port = port;

  @override
  Future<void> execute(
    CreateAllocationMutation mutation,
    FinancialTransactionContext context,
  ) {
    return _port.createAllocation(mutation);
  }
}