import 'planning_operation.dart';
import '../value_objects/planning_source_type.dart';

/// ===============================================================
/// ReleaseOperation
/// ===============================================================
///
/// Releases reserved money from a planning source.
///
/// ===============================================================
final class ReleaseOperation extends PlanningOperation {
  const ReleaseOperation({
    required super.id,
    required super.createdAt,
    required this.sourceId,
    required this.sourceType,
    required this.accountId,
    required this.amount,
  });

  /// Goal / Budget / Commitment...
  final String sourceId;

  /// Planning source type.
  final PlanningSourceType sourceType;

  /// Reserved account.
  final String accountId;

  /// Amount to release.
  final double amount;
}
