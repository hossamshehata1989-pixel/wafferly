import 'package:hive/hive.dart';

import '../models/allocation.dart';
import '../models/enums/allocation_type.dart';

class AllocationService {
  static const String boxName = 'allocations';

  Box<Allocation> get _box => Hive.box<Allocation>(boxName);

  Future<void> add(Allocation allocation) async {
    await _box.put(allocation.id, allocation);
  }

  Future<void> update(Allocation allocation) async {
    await _box.put(allocation.id, allocation);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> createSavingAllocation({
    required String accountId,
    required double amount,
    required String referenceId,
  }) async {
    final allocation = Allocation.create(
      accountId: accountId,
      amount: amount,
      type: AllocationType.saving,
      referenceId: referenceId,
    );

    await add(allocation);
  }

  List<Allocation> getAll() {
    return _box.values.toList();
  }

  List<Allocation> getByAccount(String accountId) {
    return _box.values.where((a) => a.accountId == accountId).toList();
  }

  List<Allocation> getByReference(String referenceId) {
    return _box.values.where((a) => a.referenceId == referenceId).toList();
  }

  double getAllocatedAmount(String accountId) {
    return _box.values
        .where((a) => a.accountId == accountId)
        .fold(0.0, (sum, a) => sum + a.amount);
  }

  double getTotalAllocatedAmount() {
    return _box.values.fold(0.0, (sum, item) => sum + item.amount);
  }

  double getAllocatedAmountByType(AllocationType type) {
    return _box.values
        .where((a) => a.type == type)
        .fold(0.0, (sum, a) => sum + a.amount);
  }

  double getAllocatedAmountForAccount(String accountId) {
    return _box.values
        .where((a) => a.accountId == accountId)
        .fold(0.0, (sum, a) => sum + a.amount);
  }

  List<Allocation> getByType(AllocationType type) {
    return _box.values.where((a) => a.type == type).toList();
  }
}
