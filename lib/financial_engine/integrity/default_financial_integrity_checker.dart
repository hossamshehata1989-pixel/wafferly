import '../planning/financial_execution_plan.dart';
import '../mutations/journal_entry_mutation.dart';
import 'financial_integrity_checker.dart';

final class DefaultFinancialIntegrityChecker
    implements FinancialIntegrityChecker {
  const DefaultFinancialIntegrityChecker();

  @override
  void validate(FinancialExecutionPlan plan) {
    for (final mutation in plan.mutations) {
      if (mutation is JournalEntryMutation) {
        _validateJournalEntry(mutation);
      }
    }
  }

  void _validateJournalEntry(JournalEntryMutation entry) {
    double totalDebits = 0;
    double totalCredits = 0;

    for (final line in entry.lines) {
      totalDebits += line.debit;
      totalCredits += line.credit;
    }

    if (totalDebits != totalCredits) {
      throw StateError('Journal entry is not balanced.');
    }
  }
}
