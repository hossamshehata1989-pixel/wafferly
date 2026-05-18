// lib/services/reserved_money_service.dart

import 'package:hive/hive.dart';
import '../models/reserved_money.dart';

class ReservedMoneyService {
  static const String _boxName = 'reserved_money';

  // ✅ مباشر: اعتمد على Hive
  Box<ReservedMoney> get _box => Hive.box<ReservedMoney>(_boxName);

  // ==========================================
  // 📥 CRUD Operations
  // ==========================================

  Future<void> add(ReservedMoney item) async {
    await _box.put(item.id, item);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> update(ReservedMoney item) async {
    await _box.put(item.id, item);
  }

  List<ReservedMoney> getAll() {
    return _box.values.toList();
  }

  List<ReservedMoney> getByAccount(String accountId) {
    return _box.values.where((item) => item.accountId == accountId).toList();
  }

  ReservedMoney? getById(String id) {
    return _box.get(id);
  }

  double getReservedAmount(String accountId) {
    double total = 0;

    for (final item in _box.values) {
      if (item.accountId == accountId) {
        total += item.amount;
      }
    }

    return total;
  }

  Future<void> deleteAll() async {
    await _box.clear();
  }

  int get count => _box.length;
}
