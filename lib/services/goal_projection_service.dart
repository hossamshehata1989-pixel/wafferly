import '../services/allocation_service.dart';
import '../models/enums/allocation_type.dart';

class GoalProjectionService {
  final AllocationService _allocationService = AllocationService();

  double getGoalAllocatedAmount(String goalId) {
    return _allocationService
        .getByReference(goalId)
        .where((a) => a.type == AllocationType.goal)
        .fold(0.0, (sum, a) => sum + a.amount);
  }
}
