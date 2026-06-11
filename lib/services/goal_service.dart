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

  Goal? getById(String id) {
    return _box.get(id);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
