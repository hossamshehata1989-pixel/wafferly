import '../../financial_engine/operations/create_allocation_mutation.dart';
import '../../financial_engine/ports/create_allocation_port.dart';

final class MemoryAllocationRepository implements CreateAllocationPort {
  final List<CreateAllocationMutation> _allocations = [];

  @override
  Future<void> createAllocation(CreateAllocationMutation mutation) async {
    _allocations.add(mutation);
  }

  List<CreateAllocationMutation> get allocations =>
      List.unmodifiable(_allocations);
}
