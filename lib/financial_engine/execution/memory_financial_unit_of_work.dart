import 'dart:developer' as developer;

import 'financial_transaction_context.dart';
import 'financial_unit_of_work.dart';

typedef RollbackErrorReporter =
    void Function(Object error, StackTrace stackTrace);

final class MemoryFinancialUnitOfWork implements FinancialUnitOfWork {
  final RollbackErrorReporter? _onRollbackError;

  const MemoryFinancialUnitOfWork({RollbackErrorReporter? onRollbackError})
    : _onRollbackError = onRollbackError;

  @override
  Future<void> execute(
    Future<void> Function(FinancialTransactionContext context) action,
  ) async {
    final context = _MemoryFinancialTransactionContext();

    try {
      await action(context);
    } catch (error, stackTrace) {
      await context.rollback(_reportRollbackError);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  void _reportRollbackError(Object error, StackTrace stackTrace) {
    try {
      final reporter = _onRollbackError;
      if (reporter != null) {
        reporter(error, stackTrace);
        return;
      }

      // Keep the default log free of exception messages, which may contain
      // financial or otherwise sensitive operation details.
      developer.log(
        'A financial rollback callback failed (${error.runtimeType}).',
        name: 'wafferly.financial_engine.rollback',
        level: 1000,
        stackTrace: stackTrace,
      );
    } catch (_) {
      // A reporting failure must not replace the original operation error
      // or prevent the remaining rollback callbacks from being attempted.
    }
  }
}

final class _MemoryFinancialTransactionContext
    implements FinancialTransactionContext {
  final List<Future<void> Function()> _rollbacks = [];

  @override
  void registerRollback(Future<void> Function() rollback) {
    _rollbacks.add(rollback);
  }

  Future<void> rollback(RollbackErrorReporter reportError) async {
    final callbacks = List<Future<void> Function()>.of(_rollbacks.reversed);

    for (final rollback in callbacks) {
      try {
        await rollback();
      } catch (error, stackTrace) {
        reportError(error, stackTrace);
      }
    }
  }
}
