import '../planning/journal_entry_mutation.dart';
import 'financial_mutation_handler.dart';
import '../ports/journal_entry_port.dart';

final class JournalEntryMutationHandler
    implements FinancialMutationHandler<JournalEntryMutation> {
  final JournalEntryPort _port;

  const JournalEntryMutationHandler({required JournalEntryPort port})
    : _port = port;

  @override
  Future<void> execute(JournalEntryMutation mutation) {
    return _port.persist(mutation);
  }
}
