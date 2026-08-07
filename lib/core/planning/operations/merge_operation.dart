import '../value_objects/planning_source_reference.dart';
import 'planning_operation.dart';

/// ===============================================================
/// MergeOperation
/// ===============================================================
///
/// Merges all reserved money from one Planning Source into another.
///
/// The source Planning Source becomes inactive after the merge.
///
/// ===============================================================
final class MergeOperation extends PlanningOperation {
  const MergeOperation({
    required super.id,
    required super.createdAt,
    required this.source,
    required this.target,
  });

  final PlanningSourceReference source;

  final PlanningSourceReference target;
}
