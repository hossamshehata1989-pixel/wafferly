import 'planning_source_type.dart';

/// ===============================================================
/// PlanningSourceReference
/// ===============================================================
///
/// Identifies a Planning Source inside the Planning domain.
///
/// This value object is used by PlanningOperations to reference
/// Goals, Budgets, Saving Targets, or any future planning source
/// without exposing internal Allocation identities.
///
/// ===============================================================
final class PlanningSourceReference {
  const PlanningSourceReference({required this.id, required this.type});

  final String id;

  final PlanningSourceType type;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanningSourceReference &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type;

  @override
  int get hashCode => Object.hash(id, type);
}
