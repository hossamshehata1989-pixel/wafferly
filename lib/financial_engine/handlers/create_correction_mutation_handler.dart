import '../execution/financial_mutation_handler.dart';
import '../execution/financial_transaction_context.dart';
import '../mutations/create_correction_mutation.dart';
import '../ports/correction_port.dart';
import '../ports/transaction_port.dart';
import '../../services/ledger_projection_service.dart';

final class CreateCorrectionMutationHandler
    implements FinancialMutationHandler<CreateCorrectionMutation> {
  final CorrectionPort _correctionPort;
  final TransactionPort _transactionPort;
  final LedgerProjectionService _ledgerProjectionService;

  const CreateCorrectionMutationHandler({
    required CorrectionPort correctionPort,
    required TransactionPort transactionPort,
    required LedgerProjectionService ledgerProjectionService,
  }) : _correctionPort = correctionPort,
       _transactionPort = transactionPort,
       _ledgerProjectionService = ledgerProjectionService;

  @override
  Future<void> execute(
    CreateCorrectionMutation mutation,
    FinancialTransactionContext context,
  ) async {
    final record = mutation.record;

    await _correctionPort.save(record);
    context.registerRollback(
      () => _correctionPort.delete(record.correctionId),
    );

    // The original transaction is immutable and must remain untouched.
    // Rollback therefore removes only the newly materialized corrected truth.
    await _transactionPort.save(record.after);
    context.registerRollback(
      () => _transactionPort.delete(record.after.transactionId),
    );

    await _ledgerProjectionService.projectCorrection(record);
    context.registerRollback(
      () => _ledgerProjectionService.deleteProjection(record.correctionId),
    );
  }
}
