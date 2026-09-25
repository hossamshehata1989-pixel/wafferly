import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/core/money/money.dart';
import 'package:wafferly/financial_engine/commands/expense/expense_intent.dart';
import 'package:wafferly/financial_engine/commands/shared/transaction_metadata.dart';
import 'package:wafferly/financial_engine/domain_guard/balance_domain_guard.dart';
import 'package:wafferly/financial_engine/domain_guard/domain_guard_result.dart';
import 'package:wafferly/financial_engine/execution_context/execution_context.dart';
import 'package:wafferly/financial_engine/integrity/default_financial_integrity_checker.dart';
import 'package:wafferly/financial_engine/interpretation/default_financial_interpreter.dart';
import 'package:wafferly/financial_engine/interpretation/financial_action_type.dart';
import 'package:wafferly/financial_engine/interpretation/normalized_intent.dart';
import 'package:wafferly/financial_engine/resolution/resolution.dart';
import 'package:wafferly/financial_engine/mutations/journal_entry_mutation.dart';
import 'package:wafferly/financial_engine/operations/expense_operation.dart';
import 'package:wafferly/financial_engine/planning/chart_of_accounts.dart';
import 'package:wafferly/financial_engine/planning/default_financial_planner.dart';
import 'package:wafferly/infrastructure/memory/memory_balance_port.dart';

void main() {
  test('financial planner and accounting lines remain Money-native', () async {
    const executionContext = ExecutionContext(
      idempotencyKey: 'money-consistency-expense',
    );

    final operation = ExpenseOperation(
      intent: ExpenseIntent(
        sourceAccountId: 'cash',
        amount: Money.parse('125.50'),
        categoryId: 'food',
        isExceptional: false,
      ),
      metadata: TransactionMetadata(
        occurredAt: DateTime(2026, 9, 25),
        paymentMethod: 'cash',
        currencyCode: 'EGP',
      ),
      context: executionContext,
    );

    final intent = const DefaultFinancialInterpreter().interpret(operation);

    expect(intent.action, FinancialActionType.expense);
    expect(intent.amount, Money.parse('125.50'));

    final planner = DefaultFinancialPlanner(
      chartOfAccounts: const ChartOfAccounts(),
    );
    final plan = await planner.build(
      operation.createPlanningContext(intent: intent, constraints: const []),
    );

    final journal = plan.mutations.whereType<JournalEntryMutation>().single;
    expect(journal.lines.first.debit, Money.parse('125.50'));
    expect(journal.lines.last.credit, Money.parse('125.50'));

    expect(
      () => const DefaultFinancialIntegrityChecker().validate(plan),
      returnsNormally,
    );
  });

  test('BalancePort is Money-native at the Financial Domain boundary', () async {
    final port = MemoryBalancePort(
      balances: {'cash': Money.parse('1000.25')},
    );

    expect(await port.currentBalance('cash'), Money.parse('1000.25'));
    expect(await port.availableBalance('cash'), Money.parse('1000.25'));

    final result = await BalanceDomainGuard(balancePort: port).validate(
      NormalizedIntentForTest.expense(
        amount: Money.parse('900.25'),
      ),
    );

    expect(result, isA<DomainGuardPassed>());
  });
}

/// Small test-only NormalizedIntent factory to keep the test focused on the
/// Money boundary rather than on command metadata.
final class NormalizedIntentForTest {
  static NormalizedIntent expense({required Money amount}) {
    return NormalizedIntent(
      action: FinancialActionType.expense,
      sourceAccountId: 'cash',
      amount: amount,
      categoryId: 'food',
      resolution: Resolution.execute,
    );
  }
}
