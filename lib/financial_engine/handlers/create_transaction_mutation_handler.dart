import 'package:flutter/foundation.dart';

import '../mutations/create_transaction_mutation.dart';
import '../ports/transaction_port.dart';
import '../../services/ledger_projection_service.dart';
import '../execution/financial_mutation_handler.dart';
import '../execution/financial_transaction_context.dart';

/// Executes CreateTransactionMutation.
///
/// The handler coordinates:
/// 1. Transaction persistence
/// 2. Ledger projection
///
/// It contains no accounting/business rules.
final class CreateTransactionMutationHandler
    implements FinancialMutationHandler<CreateTransactionMutation> {
  final TransactionPort _transactionPort;
  final LedgerProjectionService _ledgerProjectionService;

  CreateTransactionMutationHandler(
    this._transactionPort,
    this._ledgerProjectionService,
  );

  @override
  Future<void> execute(
    CreateTransactionMutation mutation,
    FinancialTransactionContext context,
  ) async {
    final transactionId = mutation.record.transactionId;

    debugPrint(
      'TX HANDLER: Saving transaction $transactionId',
    );

    await _transactionPort.save(mutation.record);

    context.registerRollback(() {
      return _transactionPort.delete(transactionId);
    });

    context.registerRollback(() {
      return _ledgerProjectionService.deleteProjection(transactionId);
    });

    await _ledgerProjectionService.projectRecord(
      mutation.record,
    );
  }
}