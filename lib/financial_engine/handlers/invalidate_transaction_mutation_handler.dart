import '../execution/financial_mutation_handler.dart';
import '../execution/financial_transaction_context.dart';
import '../domain/financial_invalidation_record.dart';
import '../mutations/invalidate_transaction_mutation.dart';
import '../ports/invalidation_port.dart';
import '../../services/ledger_projection_service.dart';

final class InvalidateTransactionMutationHandler
    implements FinancialMutationHandler<InvalidateTransactionMutation> {
  final InvalidationPort _invalidationPort;
  final LedgerProjectionService _ledgerProjectionService;

  const InvalidateTransactionMutationHandler({
    required InvalidationPort invalidationPort,
    required LedgerProjectionService ledgerProjectionService,
  }) : _invalidationPort = invalidationPort,
       _ledgerProjectionService = ledgerProjectionService;

  @override
  Future<void> execute(
    InvalidateTransactionMutation mutation,
    FinancialTransactionContext context,
  ) async {
    final record = mutation.record;

    final existing = await _invalidationPort.findByOriginalTransactionId(
      record.originalTransactionId,
    );
    if (existing != null) {
      if (existing.invalidationId == record.invalidationId) return;
      throw StateError(
        'Transaction is already invalidated: ${record.originalTransactionId}',
      );
    }

    await _invalidationPort.save(record);
    context.registerRollback(
      () => _invalidationPort.delete(record.invalidationId),
    );

    await _ledgerProjectionService.projectInvalidation(record);
    context.registerRollback(
      () => _ledgerProjectionService.deleteProjection(record.invalidationId),
    );
  }
}
