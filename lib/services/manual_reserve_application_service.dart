import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/planning/operations/reserve_operation.dart';
import '../core/planning/engine/planning_engine.dart';
import '../core/planning/value_objects/planning_source_type.dart';

/// Application boundary for Manual Reserve.
///
/// This service creates PlanningOperations and delegates all reservation
/// mutation to the Planning Engine. It does not create or persist a
/// ManualReserve entity.
final class ManualReserveApplicationService {
  ManualReserveApplicationService({required PlanningEngine engine, Uuid? uuid})
    : _engine = engine,
      _uuid = uuid ?? const Uuid();

  final PlanningEngine _engine;
  final Uuid _uuid;

  /// Creates a Manual Reserve and returns its Planning Source identity.
  ///
  /// The returned value is the stable `sourceId` of this reservation and
  /// must not be confused with the PlanningOperation or Allocation id.
  Future<String> reserve({
    required String accountId,
    required double amount,
    String? name,
    DateTime? createdAt,
  }) async {
    final sourceId = _uuid.v4();
    final operation = ReserveOperation(
      id: _uuid.v4(),
      createdAt: createdAt ?? DateTime.now(),
      sourceId: sourceId,
      sourceType: PlanningSourceType.manual,
      accountId: accountId,
      amount: amount,
    );

    await _engine.execute(operation);

    // Reserve names are UI metadata. The Planning Engine remains the sole
    // owner of the reservation state itself.
    final trimmedName = name?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty) {
      final box = await Hive.openBox<String>('manual_reserve_names');
      await box.put(sourceId, trimmedName);
    }

    return sourceId;
  }
}
