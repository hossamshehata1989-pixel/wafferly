import '../accounting/journal_entry_repository.dart';
import '../planning/journal_entry_mutation.dart';
import 'financial_mutation_handler.dart';

final class JournalEntryMutationHandler
    implements FinancialMutationHandler<JournalEntryMutation> {
  final JournalEntryRepository _repository;

  const JournalEntryMutationHandler({
    required JournalEntryRepository repository,
  }) : _repository = repository;

  @override
  Future<void> execute(JournalEntryMutation mutation) {
    return _repository.save(mutation);
  }
}
