import '../../../financial_engine/operations/create_allocation_mutation.dart';
import '../../../financial_engine/ports/create_allocation_port.dart';
import '../../../models/allocation.dart';
import '../../../models/enums/allocation_type.dart';
import '../../../services/allocation_service.dart';

final class CreateAllocationAdapter implements CreateAllocationPort {
  final AllocationService _service;

  CreateAllocationAdapter({AllocationService? service})
    : _service = service ?? AllocationService();

  @override
  Future<void> createAllocation(CreateAllocationMutation mutation) {
    return _service.add(
      Allocation.create(
        accountId: mutation.accountId,
        amount: mutation.amount,
        type: AllocationType.goal,
        referenceId: mutation.goalId,
      ),
    );
  }
}
