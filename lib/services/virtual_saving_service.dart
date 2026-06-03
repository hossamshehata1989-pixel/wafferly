import '../models/enums/reserved_money_type.dart';
import 'reserved_money_service.dart';

class VirtualSavingService {
  final ReservedMoneyService _reservedService = ReservedMoneyService();

  double getTotalBalance() {
    return _reservedService.getAll().fold(0, (sum, item) => sum + item.amount);
  }

  double getGoalsBalance() {
    return _reservedService
        .getAll()
        .where((e) => e.type == ReservedMoneyType.goal)
        .fold(0, (sum, item) => sum + item.amount);
  }

  double getBucketsBalance() {
    return _reservedService
        .getAll()
        .where((e) => e.type == ReservedMoneyType.bucket)
        .fold(0, (sum, item) => sum + item.amount);
  }

  double getFixedBalance() {
    return _reservedService
        .getAll()
        .where((e) => e.type == ReservedMoneyType.fixed)
        .fold(0, (sum, item) => sum + item.amount);
  }

  int getItemsCount() {
    return _reservedService.getAll().length;
  }
}
