import 'package:flutter/foundation.dart';
import '../domain/financial_transaction_record.dart';
import '../mutations/create_transaction_mutation.dart';
import '../ports/transaction_port.dart';
import '../execution/financial_mutation_handler.dart';

/// Executes CreateTransactionMutation.
///
/// This handler is responsible only for delegating the
/// FinancialTransactionRecord to the TransactionPort.
///
/// It contains no business rules.
///
/// ADR-0012:
/// Executor executes.
/// Planner decides.
///
/// ADR-0013:
/// Mapping to the persistence model happens behind the Port.
final class CreateTransactionMutationHandler
    implements FinancialMutationHandler<CreateTransactionMutation> {
  final TransactionPort _transactionPort;

  const CreateTransactionMutationHandler(this._transactionPort);

  @override
  Future<void> execute(CreateTransactionMutation mutation) async {
    debugPrint(
      'TX HANDLER: Saving transaction ${mutation.record.transactionId}',
    );

    await _transactionPort.save(mutation.record);
  }
}
