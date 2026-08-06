import '../../operations/planning_operation.dart';

/// ===============================================================
/// PlanningInterpreter
/// ===============================================================
///
/// Converts high-level PlanningOperations into executable planning
/// intents understood by the Planning Engine.
///
/// The interpreter contains no business rules.
/// It only classifies operations.
///
/// ADR References:
/// - ADR-028 Planning Engine
///
/// ===============================================================
abstract interface class PlanningInterpreter {
  PlanningIntent interpret(PlanningOperation operation);
}

/// ===============================================================
/// PlanningIntent
/// ===============================================================
///
/// Internal engine intent.
///
/// This allows the engine to reason without depending on concrete
/// operation implementations.
///
/// ===============================================================
enum PlanningIntent { reserve, release, reallocate, split, merge }
