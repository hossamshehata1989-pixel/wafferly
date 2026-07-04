import '../../financial_engine/accounting/journal_entry_repository.dart';
import '../../financial_engine/planning/journal_entry_mutation.dart';

final class MemoryJournalEntryRepository implements JournalEntryRepository {
  final List<JournalEntryMutation> _entries = [];

  @override
  Future<void> save(JournalEntryMutation journalEntry) async {
    _entries.add(journalEntry);
  }

  List<JournalEntryMutation> get entries => List.unmodifiable(_entries);
}
