import '../mutations/release_allocation_mutation.dart';

abstract interface class AllocationPort {
  Future<void> releaseAllocation(ReleaseAllocationMutation mutation);
}
