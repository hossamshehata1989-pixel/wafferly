import '../planning/entry_line.dart';
import '../planning/financial_mutation.dart';

final class JournalEntryMutation extends AccountingMutation {
  final String journalEntryId;

  final String description;

  final List<EntryLine> lines;

  const JournalEntryMutation({
    required this.journalEntryId,
    required this.description,
    required this.lines,
  });
}
