import '../value_objects/planning_source_reference.dart';
import 'planning_operation.dart';

/// ===============================================================
/// SplitOperation
/// ===============================================================
///
/// Splits reserved money from one Planning Source into another.
///
/// The source Planning Source keeps the remaining reservation,
/// while the target receives the specified amount.
///
/// The Planner is responsible for resolving Allocations and
/// producing the executable PlanningMutations.
///
/// ===============================================================
final class SplitOperation extends PlanningOperation {
  const SplitOperation({
    required super.id,
    required super.createdAt,
    required this.source,
    required this.target,
    required this.accountId,
    required this.amount,
  });

  final PlanningSourceReference source;

  final PlanningSourceReference target;

  final String accountId;

  final double amount;
}
