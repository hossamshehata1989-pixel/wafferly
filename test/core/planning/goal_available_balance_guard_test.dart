import 'package:flutter_test/flutter_test.dart';

import 'package:wafferly/core/planning/bootstrap/planning_engine_bootstrap.dart';
import 'package:wafferly/core/planning/infrastructure/repositories/memory_allocation_repository.dart';
import 'package:wafferly/core/planning/operations/reserve_operation.dart';
import 'package:wafferly/core/planning/services/available_balance_projection_service.dart';
import 'package:wafferly/core/planning/value_objects/planning_source_type.dart';

void main() {
  group('Goal Available Balance Guard', () {
    test(
      'rejects a second reservation when all account money is already reserved',
      () async {
        // ============================================================
        // STEP 1 — Shared Planning Repository
        // ============================================================

        final repository = MemoryAllocationRepository();

        final projectionService = AvailableBalanceProjectionService(
          allocationRepository: repository,
        );

        // ============================================================
        // STEP 2 — Simulated Financial Truth
        // ============================================================

        const accountId = 'account-1';

        const accountBalance = 4000.0;

        double getAccountBalance(String id) {
          if (id == accountId) {
            return accountBalance;
          }

          return 0;
        }

        // ============================================================
        // STEP 3 — Planning Engine with Available Balance Guard
        // ============================================================

        final engine = PlanningEngineBootstrap.create(
          allocationRepository: repository,
          availableBalanceProjectionService: projectionService,
          accountBalanceProvider: getAccountBalance,
        );

        // ============================================================
        // STEP 4 — First Goal reserves the entire balance
        // ============================================================

        final firstReserve = ReserveOperation(
          id: 'reserve-1',
          createdAt: DateTime(2026, 8, 9),
          sourceId: 'goal-1',
          sourceType: PlanningSourceType.goal,
          accountId: accountId,
          amount: 4000,
        );

        await engine.execute(firstReserve);

        // ============================================================
        // STEP 5 — Verify nothing remains available
        // ============================================================

        final afterFirstReserve = await projectionService.project(
          accountId: accountId,
          balance: accountBalance,
        );

        expect(afterFirstReserve.balance, 4000);
        expect(afterFirstReserve.reserved, 4000);
        expect(afterFirstReserve.available, 0);

        // ============================================================
        // STEP 6 — Second Goal tries to reserve 1000
        // ============================================================

        final secondReserve = ReserveOperation(
          id: 'reserve-2',
          createdAt: DateTime(2026, 8, 9),
          sourceId: 'goal-2',
          sourceType: PlanningSourceType.goal,
          accountId: accountId,
          amount: 1000,
        );

        // ============================================================
        // STEP 7 — Must be rejected
        // ============================================================

        expect(() => engine.execute(secondReserve), throwsA(isA<StateError>()));

        // ============================================================
        // STEP 8 — No second allocation may exist
        // ============================================================

        final allocations = await repository.findByAccount(accountId);

        expect(allocations, hasLength(1));

        expect(allocations.single.sourceId, 'goal-1');
        expect(allocations.single.amount, 4000);
      },
    );
  });
}
