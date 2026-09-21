import 'financial_transaction_context.dart';
import 'financial_unit_of_work.dart';

final class MemoryFinancialUnitOfWork
    implements FinancialUnitOfWork {
  const MemoryFinancialUnitOfWork();

  @override
  Future<void> execute(
    Future<void> Function(
      FinancialTransactionContext context,
    ) action,
  ) async {
    final context = _MemoryFinancialTransactionContext();

    try {
      await action(context);
    } catch (error) {
      await context.rollback();
      rethrow;
    }
  }
}

final class _MemoryFinancialTransactionContext
    implements FinancialTransactionContext {
  final List<Future<void> Function()> _rollbacks = [];

  @override
  void registerRollback(
    Future<void> Function() rollback,
  ) {
    _rollbacks.add(rollback);
  }

  Future<void> rollback() async {
    for (final rollback in _rollbacks.reversed) {
      await rollback();
    }
  }
}