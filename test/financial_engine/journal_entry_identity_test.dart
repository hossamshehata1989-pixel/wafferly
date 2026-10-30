import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/core/money/money.dart';
import 'package:wafferly/financial_engine/commands/balance_reconciliation/reconciliation_reason.dart';
import 'package:wafferly/financial_engine/commands/shared/transaction_metadata.dart';
import 'package:wafferly/financial_engine/execution_context/execution_context.dart';
import 'package:wafferly/financial_engine/interpretation/financial_action_type.dart';
import 'package:wafferly/financial_engine/interpretation/normalized_intent.dart';
import 'package:wafferly/financial_engine/mutations/create_transaction_mutation.dart';
import 'package:wafferly/financial_engine/mutations/journal_entry_mutation.dart';
import 'package:wafferly/financial_engine/planning/balance_reconciliation_context.dart';
import 'package:wafferly/financial_engine/planning/chart_of_accounts.dart';
import 'package:wafferly/financial_engine/planning/default_financial_planner.dart';
import 'package:wafferly/financial_engine/planning/financial_execution_plan.dart';
import 'package:wafferly/financial_engine/planning/planning_context.dart';
import 'package:wafferly/financial_engine/resolution/resolution.dart';

void main() {
  test(
    'every planned journal entry ID is derived from its financial transaction ID',
    () async {
      const planner = DefaultFinancialPlanner(
        chartOfAccounts: ChartOfAccounts(),
      );

      final contexts = <PlanningContext>[
        _context(FinancialActionType.expense, key: 'journal-id-expense'),
        _context(
          FinancialActionType.creditCardCharge,
          key: 'journal-id-card-charge',
        ),
        _context(
          FinancialActionType.creditCardPayment,
          key: 'journal-id-card-payment',
          destinationAccountId: 'credit-card-liability',
        ),
        _context(
          FinancialActionType.income,
          key: 'journal-id-income',
          categoryId: 'salary',
        ),
        _context(
          FinancialActionType.transfer,
          key: 'journal-id-transfer',
          destinationAccountId: 'savings',
        ),
        _context(
          FinancialActionType.commitmentPayment,
          key: 'journal-id-commitment',
          destinationAccountId: 'loan',
        ),
        _context(
          FinancialActionType.goalTransfer,
          key: 'journal-id-goal-transfer',
          destinationAccountId: 'goal-savings',
          goalId: 'goal-1',
        ),
        _context(
          FinancialActionType.goalSavingTransfer,
          key: 'journal-id-goal-saving-transfer',
          destinationAccountId: 'goal-savings',
          goalId: 'goal-2',
        ),
        _context(
          FinancialActionType.openingBalance,
          key: 'journal-id-opening-balance',
        ),
        _context(
          FinancialActionType.balanceReconciliation,
          key: 'journal-id-reconciliation',
          balanceReconciliation: BalanceReconciliationContext(
            accountId: 'wallet',
            systemBalance: Money.fromDouble(100),
            observedBalance: Money.fromDouble(125),
            isLiability: false,
            reason: ReconciliationReason.cashCountDifference,
          ),
        ),
      ];

      for (final context in contexts) {
        final plan = await planner.build(context);
        _expectJournalIdentity(plan);
      }
    },
  );
}

void _expectJournalIdentity(FinancialExecutionPlan plan) {
  final journal = plan.mutations.whereType<JournalEntryMutation>().single;
  final transaction = plan.mutations
      .whereType<CreateTransactionMutation>()
      .single
      .record;

  expect(
    journal.journalEntryId,
    'journal-${transaction.transactionId}',
    reason: 'Journal identity must follow its financial transaction identity.',
  );
}

PlanningContext _context(
  FinancialActionType action, {
  required String key,
  String? categoryId,
  String? destinationAccountId,
  String? goalId,
  BalanceReconciliationContext? balanceReconciliation,
}) {
  return PlanningContext(
    intent: NormalizedIntent(
      action: action,
      amount: Money.fromDouble(25),
      sourceAccountId: 'wallet',
      destinationAccountId: destinationAccountId,
      categoryId:
          categoryId ??
          (action == FinancialActionType.expense ||
                  action == FinancialActionType.creditCardCharge
              ? 'dailyTransport'
              : null),
      goalId: goalId,
      resolution: Resolution.execute,
    ),
    metadata: TransactionMetadata(
      occurredAt: DateTime(2026, 10, 30),
      paymentMethod: 'cash',
      currencyCode: 'EGP',
    ),
    executionContext: ExecutionContext(
      idempotencyKey: key,
      commitmentId: 'commitment-1',
      scheduleRuleId: 'schedule-1',
      occurrenceId: 'occurrence-1',
    ),
    balanceReconciliation: balanceReconciliation,
  );
}
