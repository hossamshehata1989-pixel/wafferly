import '../value_objects/planning_source_type.dart';
import 'planning_operation.dart';

/// ===============================================================
/// ReserveOperation
/// ===============================================================
///
/// Represents the user's intent to reserve money.
///
/// This operation contains no business logic.
/// Validation and execution are performed by the Planning Engine.
///
/// ADR References:
/// - ADR-026 PlanningOperation Contract
///
/// ===============================================================
final class ReserveOperation extends PlanningOperation {
  const ReserveOperation({
    required super.id,
    required super.createdAt,
    required this.sourceId,
    required this.sourceType,
    required this.accountId,
    required this.amount,
  });

  /// Originating planning object identifier.
  final String sourceId;

  /// Originating planning object type.
  final PlanningSourceType sourceType;

  /// Account from which money will be reserved.
  final String accountId;

  /// Requested reserve amount.
  final double amount;
}
