import 'package:flutter/foundation.dart';

/// ===============================================================
/// PlanningOperation
/// ===============================================================
///
/// Canonical immutable write primitive of the Planning Engine.
///
/// ADR References:
/// - ADR-026 PlanningOperation Contract
/// - ADR-028 Allocation Contract
///
/// ===============================================================
@immutable
abstract class PlanningOperation {
  const PlanningOperation({required this.id, required this.createdAt});

  /// Immutable unique identifier.
  final String id;

  /// Operation creation timestamp.
  final DateTime createdAt;

  @override
  String toString() => '$runtimeType($id)';
}
