import '../operations/create_allocation_mutation.dart';

abstract interface class CreateAllocationPort {
  Future<void> createAllocation(CreateAllocationMutation mutation);
}
