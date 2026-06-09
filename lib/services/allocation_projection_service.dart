import '../models/enums/allocation_type.dart';
import 'allocation_service.dart';

class AllocationProjectionService {
  final AllocationService _allocationService = AllocationService();

  double getTotalReservedMoney() {
    return _allocationService.getTotalAllocatedAmount();
  }

  double getGoalAllocationsTotal() {
    return _allocationService.getAllocatedAmountByType(AllocationType.goal);
  }

  double getSavingAllocationsTotal() {
    return _allocationService.getAllocatedAmountByType(AllocationType.saving);
  }

  double getBudgetSurplusTotal() {
    return _allocationService.getAllocatedAmountByType(
      AllocationType.budgetSurplus,
    );
  }
}
