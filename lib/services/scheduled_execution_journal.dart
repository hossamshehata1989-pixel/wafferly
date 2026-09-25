import 'package:hive/hive.dart';

/// Persistent coordination state for one scheduled financial occurrence.
///
/// This is intentionally an orchestration/recovery record, not financial
/// truth. Financial truth remains owned by FinancialOperationEngine.
class ScheduledExecutionJournal {
  static const String boxName = 'scheduled_execution_journal';

  static const String stateExecuting = 'executing';
  static const String stateFinancialSucceeded = 'financial_succeeded';
  static const String stateCompleted = 'completed';
  static const String stateFailed = 'failed';

  final Box<Map> _box;

  const ScheduledExecutionJournal(this._box);

  Map? get(String occurrenceId) => _box.get(occurrenceId);

  Future<void> markExecuting({
    required String occurrenceId,
    required String idempotencyKey,
  }) async {
    await _put(occurrenceId, {
      'occurrenceId': occurrenceId,
      'idempotencyKey': idempotencyKey,
      'state': stateExecuting,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> markFinancialSucceeded({
    required String occurrenceId,
    required String idempotencyKey,
    List<String> transactionIds = const [],
  }) async {
    await _put(occurrenceId, {
      'occurrenceId': occurrenceId,
      'idempotencyKey': idempotencyKey,
      'state': stateFinancialSucceeded,
      'transactionIds': transactionIds,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> markCompleted({required String occurrenceId}) async {
    final existing = get(occurrenceId);
    await _put(occurrenceId, {
      ...?existing,
      'occurrenceId': occurrenceId,
      'state': stateCompleted,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> markFailed({
    required String occurrenceId,
    required String idempotencyKey,
    required Object error,
  }) async {
    await _put(occurrenceId, {
      'occurrenceId': occurrenceId,
      'idempotencyKey': idempotencyKey,
      'state': stateFailed,
      'error': error.toString(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _put(String occurrenceId, Map value) async {
    await _box.put(occurrenceId, Map<String, dynamic>.from(value));
  }
}
