import '../mutations/release_allocation_mutation.dart';
import '../ports/allocation_port.dart';
import 'financial_mutation_handler.dart';
import 'financial_transaction_context.dart';

final class ReleaseAllocationMutationHandler
    implements FinancialMutationHandler<ReleaseAllocationMutation> {
  final AllocationPort _port;

  const ReleaseAllocationMutationHandler({
    required AllocationPort port,
  }) : _port = port;

  @override
  Future<void> execute(
    ReleaseAllocationMutation mutation,
    FinancialTransactionContext context,
  ) {
    return _port.releaseAllocation(mutation);
  }
}