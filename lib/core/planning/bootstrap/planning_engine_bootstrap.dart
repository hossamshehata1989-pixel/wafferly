import '../engine/executor/default_planning_executor.dart';
import '../engine/guards/planning_guard_pipeline.dart';
import '../engine/integrity/default_planning_integrity_checker.dart';
import '../engine/interpreter/default_planning_interpreter.dart';
import '../engine/planner/default_planning_planner.dart';
import '../engine/planning_engine.dart';
import '../engine/policies/planning_policy_pipeline.dart';
import '../infrastructure/repositories/memory_allocation_repository.dart';
import '../ports/allocation_repository.dart';
import '../engine/guards/positive_amount_guard.dart';
import '../engine/guards/cannot_release_more_than_reserved_guard.dart';
import '../ports/allocation_id_generator.dart';
import '../infrastructure/identity/memory_allocation_id_generator.dart';
import '../engine/planner/handlers/reserve_planner.dart';
import '../engine/planner/handlers/release_planner.dart';
import '../engine/planner/handlers/split_planner.dart';
import '../engine/planner/handlers/merge_planner.dart';

final class PlanningEngineBootstrap {
  const PlanningEngineBootstrap._();

  static PlanningEngine create() {
    // Infrastructure

    final AllocationRepository repository = MemoryAllocationRepository();
    final AllocationIdGenerator idGenerator = MemoryAllocationIdGenerator();
    return PlanningEngine(
      interpreter: const DefaultPlanningInterpreter(),
      guards: PlanningGuardPipeline(
        guards: [
          const PositiveAmountGuard(),
          CannotReleaseMoreThanReservedGuard(repository: repository),
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
      ),
      integrity: const DefaultPlanningIntegrityChecker(),
      executor: DefaultPlanningExecutor(
        repository: repository,
        idGenerator: idGenerator,
      ),
    );
  }
}
