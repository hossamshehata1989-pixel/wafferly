import '../../entities/allocation.dart';
import '../../ports/allocation_repository.dart';
import '../../value_objects/allocation_status.dart';

/// ===============================================================
/// MemoryAllocationRepository
/// ===============================================================
///
/// In-memory implementation of AllocationRepository.
///
/// Intended for:
/// - Unit tests
/// - Early engine development
/// - Debugging
///
/// ===============================================================
final class MemoryAllocationRepository implements AllocationRepository {
  final Map<String, Allocation> _storage = {};

  @override
  Future<void> create(Allocation allocation) async {
    _storage[allocation.id] = allocation;
  }

  @override
  Future<void> update(Allocation allocation) async {
    _storage[allocation.id] = allocation;
  }

  @override
  Future<Allocation?> findById(String allocationId) async {
    return _storage[allocationId];
  }

  @override
  Future<List<Allocation>> findBySource(String sourceId) async {
    return _storage.values.where((a) => a.sourceId == sourceId).toList();
  }

  @override
  Future<List<Allocation>> findByAccount(String accountId) async {
    return _storage.values.where((a) => a.accountId == accountId).toList();
  }

  @override
  Future<List<Allocation>> findActive() async {
    return _storage.values
        .where((a) => a.status == AllocationStatus.active)
        .toList();
  }

  @override
  Future<void> delete(String allocationId) async {
    _storage.remove(allocationId);
  }

  @override
  Future<Allocation?> findCurrentBySource(String sourceId) async {
    try {
      return _storage.values.firstWhere(
        (allocation) => allocation.sourceId == sourceId,
      );
    } catch (_) {
      return null;
    }
  }
}
