import '../value_objects/planning_source_reference.dart';
import 'planning_operation.dart';

/// ===============================================================
/// ReallocateOperation
/// ===============================================================
///
/// Moves a specified reserved amount from one Planning Source
/// to another existing Planning Source.
///
/// ===============================================================
final class ReallocateOperation extends PlanningOperation {
  const ReallocateOperation({
    required super.id,
    required super.createdAt,
    required this.source,
    required this.target,
    required this.amount,
  });

  final PlanningSourceReference source;

  final PlanningSourceReference target;

  final double amount;
}
