import 'package:flutter_test/flutter_test.dart';

import 'package:wafferly/core/planning/entities/allocation.dart';
import 'package:wafferly/core/planning/ports/allocation_repository.dart';
import 'package:wafferly/core/planning/services/available_balance_projection_service.dart';
import 'package:wafferly/core/planning/value_objects/allocation_status.dart';
import 'package:wafferly/core/planning/value_objects/planning_source_type.dart';

class _FakeAllocationRepository implements AllocationRepository {
  final List<Allocation> allocations = [];

  @override
  Future<void> create(Allocation allocation) async {
    allocations.add(allocation);
  }

  @override
  Future<void> update(Allocation allocation) async {}

  @override
  Future<Allocation?> findById(String allocationId) async {
    for (final allocation in allocations) {
      if (allocation.id == allocationId) {
        return allocation;
      }
    }
    return null;
  }

  @override
  Future<List<Allocation>> findBySource(String sourceId) async {
    return allocations
        .where((allocation) => allocation.sourceId == sourceId)
        .toList();
  }

  @override
  Future<List<Allocation>> findByAccount(String accountId) async {
    return allocations
        .where((allocation) => allocation.accountId == accountId)
        .toList();
  }

  @override
  Future<List<Allocation>> findActive() async {
    return allocations
        .where((allocation) => allocation.status == AllocationStatus.active)
        .toList();
  }

  @override
  Future<void> delete(String allocationId) async {}

  @override
  Future<Allocation?> findActiveBySource(String sourceId) async {
    for (final allocation in allocations) {
      if (allocation.sourceId == sourceId &&
          allocation.status == AllocationStatus.active) {
        return allocation;
      }
    }

    return null;
  }
}

void main() {
  group('AvailableBalanceProjectionService', () {
    test('calculates reserved and available from active allocations', () async {
      final repository = _FakeAllocationRepository();

      await repository.create(
        Allocation(
          id: 'allocation-1',
          sourceId: 'manual-1',
          sourceType: PlanningSourceType.manual,
          accountId: 'account-1',
          amount: 1500,
          createdAt: DateTime(2026, 8, 8),
        ),
      );

      final service = AvailableBalanceProjectionService(
        allocationRepository: repository,
      );

      final projection = await service.project(
        accountId: 'account-1',
        balance: 5000,
      );

      expect(projection.accountId, 'account-1');
      expect(projection.balance, 5000);
      expect(projection.reserved, 1500);
      expect(projection.available, 3500);
    });

    test('ignores non-active allocations', () async {
      final repository = _FakeAllocationRepository();

      await repository.create(
        Allocation(
          id: 'allocation-active',
          sourceId: 'manual-active',
          sourceType: PlanningSourceType.manual,
          accountId: 'account-2',
          amount: 1000,
          createdAt: DateTime(2026, 8, 8),
          status: AllocationStatus.active,
        ),
      );

      await repository.create(
        Allocation(
          id: 'allocation-released',
          sourceId: 'manual-released',
          sourceType: PlanningSourceType.manual,
          accountId: 'account-2',
          amount: 2000,
          createdAt: DateTime(2026, 8, 8),
          status: AllocationStatus.released,
        ),
      );

      final service = AvailableBalanceProjectionService(
        allocationRepository: repository,
      );

      final projection = await service.project(
        accountId: 'account-2',
        balance: 5000,
      );

      expect(projection.reserved, 1000);
      expect(projection.available, 4000);
    });
  });
}
