import '../planning/journal_entry_mutation.dart';

abstract interface class JournalEntryRepository {
  Future<void> save(JournalEntryMutation journalEntry);
}
