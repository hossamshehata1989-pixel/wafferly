import 'package:flutter_test/flutter_test.dart';

import 'package:wafferly/core/money/money.dart';
import 'package:wafferly/core/planning/bootstrap/planning_engine_bootstrap.dart';
import 'package:wafferly/core/planning/entities/allocation.dart';
import 'package:wafferly/core/planning/infrastructure/repositories/memory_allocation_repository.dart';
import 'package:wafferly/core/planning/value_objects/allocation_status.dart';
import 'package:wafferly/core/planning/value_objects/planning_source_type.dart';
import 'package:wafferly/financial_engine/execution/memory_financial_unit_of_work.dart';
import 'package:wafferly/financial_engine/mutations/release_allocation_mutation.dart';
import 'package:wafferly/infrastructure/adapters/allocation_adapter.dart';

void main() {
  test(
    'allocation is restored when a later financial mutation fails',
    () async {
      final allocationRepository = MemoryAllocationRepository();

      final originalUpdatedAt = DateTime(2026, 9, 21, 10, 30);

      final originalAllocation = Allocation(
        id: 'allocation-rollback-001',
        sourceId: 'goal-rollback-001',
        sourceType: PlanningSourceType.goal,
        accountId: 'cash',
        amount: Money.parse('500'),
        status: AllocationStatus.active,
        version: 7,
        createdAt: DateTime(2026, 9, 1),
        updatedAt: originalUpdatedAt,
      );

      await allocationRepository.create(originalAllocation);

      final planningEngine = PlanningEngineBootstrap.create(
        allocationRepository: allocationRepository,
      );

     final allocationAdapter = AllocationAdapter(
  planningEngine: planningEngine,
  allocationRepository: allocationRepository,
);

      final unitOfWork = const MemoryFinancialUnitOfWork();

      final mutation = ReleaseAllocationMutation(
        goalId: 'goal-rollback-001',
        accountId: 'cash',
        amount: Money.fromDouble(200),
      );

      await expectLater(
        unitOfWork.execute(
          (context) async {
            await allocationAdapter.releaseAllocation(
  mutation,
  context,
);

            final releasedAllocation =
                await allocationRepository.findById(
              'allocation-rollback-001',
            );

            expect(releasedAllocation, isNotNull);
            expect(
              releasedAllocation!.amount,
              Money.parse('300'),
            );
            expect(
              releasedAllocation.status,
              AllocationStatus.active,
            );
            expect(releasedAllocation.version, 8);

            throw StateError('Simulated later financial failure');
          },
        ),
        throwsA(isA<StateError>()),
      );

      final restoredAllocation =
          await allocationRepository.findById(
        'allocation-rollback-001',
      );

      expect(restoredAllocation, isNotNull);

      expect(
        restoredAllocation!.amount,
        originalAllocation.amount,
      );
      expect(
        restoredAllocation.status,
        originalAllocation.status,
      );
      expect(
        restoredAllocation.version,
        originalAllocation.version,
      );
      expect(
        restoredAllocation.createdAt,
        originalAllocation.createdAt,
      );
      expect(
        restoredAllocation.updatedAt,
        originalAllocation.updatedAt,
      );
      expect(
        restoredAllocation.id,
        originalAllocation.id,
      );
      expect(
        restoredAllocation.sourceId,
        originalAllocation.sourceId,
      );
      expect(
        restoredAllocation.accountId,
        originalAllocation.accountId,
      );
    },
  );
}