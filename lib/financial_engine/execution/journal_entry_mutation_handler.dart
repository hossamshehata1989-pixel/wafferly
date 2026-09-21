import '../mutations/journal_entry_mutation.dart';
import '../ports/journal_entry_port.dart';
import 'financial_mutation_handler.dart';
import 'financial_transaction_context.dart';

final class JournalEntryMutationHandler
    implements FinancialMutationHandler<JournalEntryMutation> {
  final JournalEntryPort _port;

  const JournalEntryMutationHandler({
    required JournalEntryPort port,
  }) : _port = port;

  @override
  Future<void> execute(
    JournalEntryMutation mutation,
    FinancialTransactionContext context,
  ) async {
    await _port.persist(mutation);

    context.registerRollback(() {
      return _port.delete(mutation.journalEntryId);
    });
  }
}