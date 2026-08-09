import 'package:flutter_test/flutter_test.dart';

import 'package:wafferly/core/planning/bootstrap/planning_engine_bootstrap.dart';
import 'package:wafferly/core/planning/infrastructure/repositories/memory_allocation_repository.dart';
import 'package:wafferly/core/planning/operations/reserve_operation.dart';
import 'package:wafferly/core/planning/services/available_balance_projection_service.dart';
import 'package:wafferly/core/planning/value_objects/planning_source_type.dart';

void main() {
  group('Goal Available Balance Integration', () {
    test(
      'goal reservation reduces available balance without changing account balance',
      () async {
        // ============================================================
        // STEP 1 — Planning Repository + Engine
        // ============================================================

        final repository = MemoryAllocationRepository();

        final engine = PlanningEngineBootstrap.create(
          allocationRepository: repository,
        );

        // ============================================================
        // STEP 2 — Initial account state
        // ============================================================

        const accountId = 'account-1';
        const goalId = 'goal-1';

        const accountBalance = 1000.0;

        // ============================================================
        // STEP 3 — Reserve 300 for the Goal
        // ============================================================

        final operation = ReserveOperation(
          id: 'operation-1',
          createdAt: DateTime(2026, 8, 8),
          sourceId: goalId,
          sourceType: PlanningSourceType.goal,
          accountId: accountId,
          amount: 300,
        );

        await engine.execute(operation);

        // ============================================================
        // STEP 4 — Build Available Balance Projection
        // ============================================================

        final projectionService = AvailableBalanceProjectionService(
          allocationRepository: repository,
        );

        final projection = await projectionService.project(
          accountId: accountId,
          balance: accountBalance,
        );

        // ============================================================
        // STEP 5 — Verify Financial Truth
        // ============================================================

        expect(projection.accountId, accountId);

        // The actual account balance did NOT change.
        expect(projection.balance, 1000);

        // The Goal reservation is now reserved money.
        expect(projection.reserved, 300);

        // Therefore only 700 remains available.
        expect(projection.available, 700);
      },
    );
  });
}
