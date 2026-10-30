import '../../financial_engine/accounting/journal_entry_repository.dart';
import '../../financial_engine/mutations/journal_entry_mutation.dart';
import '../../financial_engine/ports/journal_entry_port.dart';

final class MemoryJournalEntryRepository
    implements JournalEntryRepository, JournalEntryPort {
  final List<JournalEntryMutation> _entries = [];

  @override
  Future<void> save(JournalEntryMutation journalEntry) async {
    _entries.add(journalEntry);
  }

  @override
  Future<void> persist(JournalEntryMutation mutation) {
    return save(mutation);
  }

  @override
  Future<void> delete(JournalEntryMutation mutation) async {
    final index = _entries.indexWhere((entry) => identical(entry, mutation));

    if (index == -1) {
      throw StateError(
        'Journal mutation not found: ${mutation.journalEntryId}',
      );
    }

    _entries.removeAt(index);
  }

  List<JournalEntryMutation> get entries => List.unmodifiable(_entries);
}
