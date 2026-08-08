import 'package:flutter_test/flutter_test.dart';

import 'package:wafferly/core/planning/bootstrap/planning_engine_bootstrap.dart';
import 'package:wafferly/core/planning/infrastructure/repositories/memory_allocation_repository.dart';
import 'package:wafferly/core/planning/value_objects/allocation_status.dart';
import 'package:wafferly/services/manual_reserve_application_service.dart';

void main() {
  group('ManualReserveApplicationService', () {
    test(
      'creates an active manual allocation through the Planning Engine',
      () async {
        final repository = MemoryAllocationRepository();
        final engine = PlanningEngineBootstrap.create(
          allocationRepository: repository,
        );
        final service = ManualReserveApplicationService(engine: engine);

        final sourceId = await service.reserve(
          accountId: 'account-1',
          amount: 1500,
        );

        final allocations = await repository.findBySource(sourceId);

        expect(allocations, hasLength(1));
        expect(allocations.single.sourceId, sourceId);
        expect(allocations.single.sourceType.name, 'manual');
        expect(allocations.single.accountId, 'account-1');
        expect(allocations.single.amount, 1500);
        expect(allocations.single.status, AllocationStatus.active);
      },
    );
  });
}
