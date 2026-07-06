import '../../financial_engine/ports/journal_entry_port.dart';
import '../../financial_engine/planning/journal_entry_mutation.dart';
import '../memory/memory_journal_entry_repository.dart';

final class MemoryJournalEntryAdapter implements JournalEntryPort {
  final MemoryJournalEntryRepository repository;

  const MemoryJournalEntryAdapter({required this.repository});

  @override
  Future<void> persist(JournalEntryMutation mutation) {
    return repository.save(mutation);
  }
}
