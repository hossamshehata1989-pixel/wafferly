import 'package:hive/hive.dart';

import '../../entities/allocation.dart';
import '../../ports/allocation_repository.dart';
import '../../value_objects/allocation_status.dart';
import '../persistence/hive_allocation_record.dart';

/// Persistent Hive implementation of the Planning AllocationRepository.
///
/// The Planning Engine only sees AllocationRepository. Hive remains an
/// Infrastructure concern.
final class HiveAllocationRepository implements AllocationRepository {
  const HiveAllocationRepository(this._box);

  final Box<HiveAllocationRecord> _box;

  @override
  Future<void> create(Allocation allocation) async {
    await _box.put(allocation.id, HiveAllocationRecord.fromDomain(allocation));
  }

  @override
  Future<void> update(Allocation allocation) async {
    await _box.put(allocation.id, HiveAllocationRecord.fromDomain(allocation));
  }

  @override
  Future<Allocation?> findById(String allocationId) async {
    return _box.get(allocationId)?.toDomain();
  }

  @override
  Future<List<Allocation>> findBySource(String sourceId) async {
    return _box.values
        .where((record) => record.sourceId == sourceId)
        .map((record) => record.toDomain())
        .toList(growable: false);
  }

  @override
  Future<List<Allocation>> findByAccount(String accountId) async {
    return _box.values
        .where((record) => record.accountId == accountId)
        .map((record) => record.toDomain())
        .toList(growable: false);
  }

  @override
  Future<List<Allocation>> findActive() async {
    return _box.values
        .where((record) => record.statusIndex == AllocationStatus.active.index)
        .map((record) => record.toDomain())
        .toList(growable: false);
  }

  @override
  Future<void> delete(String allocationId) async {
    await _box.delete(allocationId);
  }

  @override
  Future<Allocation?> findActiveBySource(String sourceId) async {
    for (final record in _box.values) {
      if (record.sourceId == sourceId &&
          record.statusIndex == AllocationStatus.active.index) {
        return record.toDomain();
      }
    }
    return null;
  }
}
