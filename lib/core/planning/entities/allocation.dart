import 'package:flutter/foundation.dart';

import '../value_objects/allocation_status.dart';
import '../value_objects/planning_source_type.dart';

/// ===============================================================
/// Allocation
/// ===============================================================
///
/// Represents reserved money inside the Planning Engine.
///
/// Allocation is the mutable operational state managed exclusively
/// by the Planning Engine.
///
/// It is NOT:
/// - Financial truth
/// - Ledger
/// - Event log
///
/// ADR References:
/// - ADR-028 Allocation Contract
///
/// ===============================================================
@immutable
final class Allocation {
  const Allocation({
    required this.id,
    required this.sourceId,
    required this.sourceType,
    required this.accountId,
    required this.amount,
    required this.createdAt,
    this.status = AllocationStatus.active,
    this.version = 1,
    this.updatedAt,
  });

  /// Allocation identity.
  final String id;

  /// Originating planning object identifier.
  ///
  /// Examples:
  /// - Goal ID
  /// - Budget ID
  /// - Commitment ID
  /// - Manual Reserve ID
  final String sourceId;

  /// Originating planning object type.
  final PlanningSourceType sourceType;

  /// Account from which money is reserved.
  final String accountId;

  /// Reserved amount.
  final double amount;

  /// Current lifecycle state.
  final AllocationStatus status;

  /// Optimistic concurrency version.
  final int version;

  /// Allocation creation timestamp.
  final DateTime createdAt;

  /// Last successful update timestamp.
  final DateTime? updatedAt;

  Allocation copyWith({
    String? id,
    String? sourceId,
    PlanningSourceType? sourceType,
    String? accountId,
    double? amount,
    AllocationStatus? status,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Allocation(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      sourceType: sourceType ?? this.sourceType,
      accountId: accountId ?? this.accountId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
