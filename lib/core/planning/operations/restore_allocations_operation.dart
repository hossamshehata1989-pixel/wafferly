import 'package:flutter/foundation.dart';

import '../entities/allocation.dart';
import 'planning_operation.dart';

/// Internal compensation operation used to restore Allocation snapshots
/// after a Financial Engine transaction rolls back.
///
/// The operation deliberately carries immutable snapshots so compensation
/// restores the exact Planning state that existed before the financial
/// transaction, including version and timestamps.
@immutable
final class RestoreAllocationsOperation extends PlanningOperation {
  RestoreAllocationsOperation({
    required super.id,
    required super.createdAt,
    required List<Allocation> snapshots,
  }) : snapshots = List<Allocation>.unmodifiable(snapshots);

  final List<Allocation> snapshots;
}
