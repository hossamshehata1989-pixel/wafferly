// lib/services/goal_service.dart

import 'package:hive/hive.dart';
import '../models/goal.dart';

class GoalService {
  static const boxName = "goals";

  Box<Goal> get _box => Hive.box<Goal>(boxName);

  Future<void> add(Goal goal) async {
    await _box.put(goal.id, goal);
  }

  // ✅ إضافة update() - جديدة
  Future<void> update(Goal goal) async {
    await _box.put(goal.id, goal);
  }

  List<Goal> getAll() {
    return _box.values.toList();
  }

  List<Goal> getByAccount(String accountId) {
    return _box.values.where((g) => g.accountId == accountId).toList();
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
