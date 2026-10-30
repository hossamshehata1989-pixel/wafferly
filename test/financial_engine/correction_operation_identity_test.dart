import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/constants/transaction_constants.dart';
import 'package:wafferly/core/money/money.dart';
import 'package:wafferly/financial_engine/commands/shared/transaction_metadata.dart';
import 'package:wafferly/financial_engine/domain/financial_transaction_record.dart';
import 'package:wafferly/financial_engine/execution_context/execution_context.dart';
import 'package:wafferly/financial_engine/interpretation/financial_action_type.dart';
import 'package:wafferly/financial_engine/interpretation/normalized_intent.dart';
import 'package:wafferly/financial_engine/mutations/create_correction_mutation.dart';
import 'package:wafferly/financial_engine/planning/chart_of_accounts.dart';
import 'package:wafferly/financial_engine/planning/correction_context.dart';
import 'package:wafferly/financial_engine/planning/default_financial_planner.dart';
import 'package:wafferly/financial_engine/planning/planning_context.dart';
import 'package:wafferly/financial_engine/resolution/resolution.dart';

void main() {
  test(
    'independent correction sessions with different operation keys get different correction identities',
    () async {
      const planner = DefaultFinancialPlanner(
        chartOfAccounts: ChartOfAccounts(),
      );
      final before = _record(amount: 100);

      final firstPlan = await planner.build(
        _correctionContext(
          key: 'edit-session-001',
          before: before,
          after: _record(amount: 125),
        ),
      );
      final secondPlan = await planner.build(
        _correctionContext(
          key: 'edit-session-002',
          before: before,
          after: _record(amount: 150),
        ),
      );

      final firstCorrection =
          (firstPlan.mutations.single as CreateCorrectionMutation).record;
      final secondCorrection =
          (secondPlan.mutations.single as CreateCorrectionMutation).record;

      expect(firstCorrection.correctionId, 'correction-edit-session-001');
      expect(secondCorrection.correctionId, 'correction-edit-session-002');
      expect(firstCorrection.correctionId, isNot(secondCorrection.correctionId));
      expect(
        firstCorrection.after.transactionId,
        isNot(secondCorrection.after.transactionId),
      );
    },
  );
}

PlanningContext _correctionContext({
  required String key,
  required FinancialTransactionRecord before,
  required FinancialTransactionRecord after,
}) {
  return PlanningContext(
    intent: NormalizedIntent(
      action: FinancialActionType.correction,
      amount: Money.fromDouble(25),
      sourceAccountId: 'wallet',
      categoryId: 'dailyTransport',
      resolution: Resolution.execute,
    ),
    metadata: TransactionMetadata(
      occurredAt: DateTime(2026, 1, 2),
      paymentMethod: 'cash',
      currencyCode: 'EGP',
    ),
    executionContext: ExecutionContext(
      idempotencyKey: key,
      source: 'manual',
      commandType: 'CorrectionCommand',
    ),
    correction: CorrectionContext(
      transactionId: 'txn-original',
      before: before,
      after: after,
    ),
  );
}

FinancialTransactionRecord _record({required double amount}) {
  return FinancialTransactionRecord(
    transactionId: 'txn-original',
    type: TransactionType.expense,
    fromAccountId: 'wallet',
    categoryId: 'dailyTransport',
    amount: Money.fromDouble(amount),
    currencyCode: 'EGP',
    paymentMethod: 'cash',
    occurredAt: DateTime(2026, 1, 2),
    isExceptional: false,
    source: 'manual',
  );
}
