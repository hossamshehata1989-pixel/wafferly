import '../execution/financial_transaction_context.dart';
import '../mutations/release_allocation_mutation.dart';

abstract interface class AllocationPort {
  Future<void> releaseAllocation(
    ReleaseAllocationMutation mutation,
    FinancialTransactionContext context,
  );
}