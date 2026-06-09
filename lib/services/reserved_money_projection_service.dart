import '../models/enums/allocation_type.dart';
import 'allocation_service.dart';

class ReservedMoneyProjectionService {
  final AllocationService _allocationService = AllocationService();

  double getTotalReservedAmount() {
    return _allocationService.getTotalAllocatedAmount();
  }

  double getGoalReservedAmount() {
    return _allocationService.getAllocatedAmountByType(AllocationType.goal);
  }

  double getSavingReservedAmount() {
    return _allocationService.getAllocatedAmountByType(AllocationType.saving);
  }

  double getBudgetSurplusReservedAmount() {
    return _allocationService.getAllocatedAmountByType(
      AllocationType.budgetSurplus,
    );
  }
}
