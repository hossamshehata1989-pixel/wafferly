import '../../core/money/money.dart';
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
    Money totalDebits = Money.zero;
    Money totalCredits = Money.zero;

    for (final line in entry.lines) {
      totalDebits = totalDebits + line.debit;
      totalCredits = totalCredits + line.credit;
    }

    if (totalDebits != totalCredits) {
      throw StateError('Journal entry is not balanced.');
    }
  }
}
