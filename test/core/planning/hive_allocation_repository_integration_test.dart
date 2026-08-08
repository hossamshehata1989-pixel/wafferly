import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:wafferly/core/planning/bootstrap/planning_engine_bootstrap.dart';
import 'package:wafferly/core/planning/entities/allocation.dart';
import 'package:wafferly/core/planning/infrastructure/persistence/hive_allocation_record.dart';
import 'package:wafferly/core/planning/infrastructure/repositories/hive_allocation_repository.dart';
import 'package:wafferly/core/planning/operations/reserve_operation.dart';
import 'package:wafferly/core/planning/value_objects/allocation_status.dart';
import 'package:wafferly/core/planning/value_objects/planning_source_type.dart';

void main() {
  late Directory testDirectory;
  late Box<HiveAllocationRecord> box;

  setUpAll(() async {
    testDirectory = await Directory.systemTemp.createTemp(
      'wafferly_planning_test_',
    );

    Hive.init(testDirectory.path);

    if (!Hive.isAdapterRegistered(97)) {
      Hive.registerAdapter(HiveAllocationRecordAdapter());
    }

    box = await Hive.openBox<HiveAllocationRecord>('planning_allocations_test');
  });

  tearDownAll(() async {
    await box.close();
    await Hive.deleteBoxFromDisk('planning_allocations_test');
    await testDirectory.delete(recursive: true);
  });

  setUp(() async {
    await box.clear();
  });

  test('ReserveOperation persists an active Allocation through Hive', () async {
    final repository = HiveAllocationRepository(box);

    final engine = PlanningEngineBootstrap.create(
      allocationRepository: repository,
    );

    const sourceId = 'manual-reserve-source-001';
    const operationId = 'reserve-operation-001';

    final operation = ReserveOperation(
      id: operationId,
      createdAt: DateTime(2026, 8, 8),
      sourceId: sourceId,
      sourceType: PlanningSourceType.manual,
      accountId: 'account-001',
      amount: 1500,
    );

    await engine.execute(operation);

    final allocations = await repository.findByAccount('account-001');

    expect(allocations, hasLength(1));

    final allocation = allocations.single;

    expect(allocation.sourceId, sourceId);
    expect(allocation.sourceType, PlanningSourceType.manual);
    expect(allocation.accountId, 'account-001');
    expect(allocation.amount, 1500);
    expect(allocation.status, AllocationStatus.active);

    expect(box.length, 1);
  });

  test(
    'persisted Allocation can be read back after repository recreation',
    () async {
      final repository = HiveAllocationRepository(box);

      final engine = PlanningEngineBootstrap.create(
        allocationRepository: repository,
      );

      const sourceId = 'manual-reserve-source-002';

      final operation = ReserveOperation(
        id: 'reserve-operation-002',
        createdAt: DateTime(2026, 8, 8),
        sourceId: sourceId,
        sourceType: PlanningSourceType.manual,
        accountId: 'account-002',
        amount: 2000,
      );

      await engine.execute(operation);

      // Simulate a new repository instance reading the same persistent box.
      final recreatedRepository = HiveAllocationRepository(box);

      final allocation = await recreatedRepository.findActiveBySource(sourceId);

      expect(allocation, isNotNull);
      expect(allocation!.sourceId, sourceId);
      expect(allocation.sourceType, PlanningSourceType.manual);
      expect(allocation.accountId, 'account-002');
      expect(allocation.amount, 2000);
      expect(allocation.status, AllocationStatus.active);
    },
  );
}
