import '../planning/journal_entry_mutation.dart';

abstract interface class JournalEntryPort {
  Future<void> persist(JournalEntryMutation mutation);
}
