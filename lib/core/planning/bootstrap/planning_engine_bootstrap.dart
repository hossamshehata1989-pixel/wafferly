import 'package:hive/hive.dart';

import '../engine/executor/default_planning_executor.dart';
import '../engine/guards/cannot_release_more_than_reserved_guard.dart';
import '../engine/guards/cannot_reserve_more_than_available_guard.dart';
import '../engine/guards/planning_guard_pipeline.dart';
import '../engine/guards/positive_amount_guard.dart';
import '../engine/integrity/default_planning_integrity_checker.dart';
import '../engine/interpreter/default_planning_interpreter.dart';
import '../engine/planner/default_planning_planner.dart';
import '../engine/planner/handlers/merge_planner.dart';
import '../engine/planner/handlers/reallocate_planner.dart';
import '../engine/planner/handlers/release_planner.dart';
import '../engine/planner/handlers/reserve_planner.dart';
import '../engine/planner/handlers/split_planner.dart';
import '../engine/planning_engine.dart';
import '../engine/policies/planning_policy_pipeline.dart';
import '../infrastructure/identity/memory_allocation_id_generator.dart';
import '../infrastructure/persistence/hive_allocation_record.dart';
import '../infrastructure/repositories/hive_allocation_repository.dart';
import '../infrastructure/repositories/memory_allocation_repository.dart';
import '../ports/allocation_id_generator.dart';
import '../ports/allocation_repository.dart';
import '../services/available_balance_projection_service.dart';

final class PlanningEngineBootstrap {
  const PlanningEngineBootstrap._();

  /// Creates the Planning Engine.
  ///
  /// Production can inject the persistent Hive repository.
  /// Tests/debugging can continue using MemoryAllocationRepository by
  /// omitting [allocationRepository].
  ///
  /// When [availableBalanceProjectionService] and
  /// [accountBalanceProvider] are supplied, reservations are also
  /// protected against consuming money that is already reserved
  /// elsewhere.
  static PlanningEngine create({
    AllocationRepository? allocationRepository,
    AvailableBalanceProjectionService? availableBalanceProjectionService,
    double Function(String accountId)? accountBalanceProvider,
  }) {
    final AllocationRepository repository =
        allocationRepository ?? MemoryAllocationRepository();

    final AllocationIdGenerator idGenerator = MemoryAllocationIdGenerator();

    return PlanningEngine(
      interpreter: const DefaultPlanningInterpreter(),

      guards: PlanningGuardPipeline(
        guards: [
          const PositiveAmountGuard(),

          CannotReleaseMoreThanReservedGuard(repository: repository),

          if (availableBalanceProjectionService != null &&
              accountBalanceProvider != null)
            CannotReserveMoreThanAvailableGuard(
              availableBalanceProjectionService:
                  availableBalanceProjectionService,
              accountBalanceProvider: accountBalanceProvider,
            ),
        ],
      ),

      policies: const PlanningPolicyPipeline(policies: []),

      planner: DefaultPlanningPlanner(
        reservePlanner: ReservePlanner(idGenerator: idGenerator),

        releasePlanner: ReleasePlanner(repository: repository),

        splitPlanner: SplitPlanner(
          repository: repository,
          idGenerator: idGenerator,
        ),

        mergePlanner: MergePlanner(repository: repository),

        reallocatePlanner: ReallocatePlanner(repository: repository),
      ),

      integrity: const DefaultPlanningIntegrityChecker(),

      executor: DefaultPlanningExecutor(
        repository: repository,
        idGenerator: idGenerator,
      ),
    );
  }

  /// Creates the persistent Allocation repository used by production.
  ///
  /// This repository is intentionally exposed so the same instance can be
  /// shared by the Planning Engine and Planning read-side services.
  static AllocationRepository createProductionAllocationRepository() {
    final box = Hive.box<HiveAllocationRecord>('planning_allocations');

    return HiveAllocationRepository(box);
  }

  /// Convenience factory for the persistent application configuration.
  ///
  /// Note:
  /// This factory creates the Planning Engine with the persistent
  /// Allocation repository, but does not enable the available-balance
  /// reservation guard because the Financial Balance provider belongs
  /// to the application composition root.
  ///
  /// Production code that needs the available-balance guard should use
  /// [create] and explicitly provide:
  ///
  /// - [availableBalanceProjectionService]
  /// - [accountBalanceProvider]
  static PlanningEngine createProduction() {
    return create(allocationRepository: createProductionAllocationRepository());
  }
}
