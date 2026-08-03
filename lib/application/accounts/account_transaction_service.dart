import 'package:wafferly/financial_engine/commands/opening_balance/opening_balance_intent.dart';
import 'package:wafferly/financial_engine/commands/shared/transaction_metadata.dart';
import 'package:wafferly/financial_engine/engine/financial_operation_engine.dart';
import 'package:wafferly/financial_engine/execution_context/execution_context.dart';
import 'package:wafferly/financial_engine/operations/opening_balance_operation.dart';
import 'package:wafferly/financial_engine/results/operation_result.dart';
import 'package:wafferly/models/account.dart';
import 'package:wafferly/models/enums/section_type.dart';

class AccountTransactionService {
  final FinancialOperationEngine _engine;

  const AccountTransactionService({required FinancialOperationEngine engine})
    : _engine = engine;

  Future<void> createInitialBalance({
    required Account account,
    required double balance,
    required SectionType sectionType,
    required String paymentMethod,
    required String currency,
  }) async {
    final isLiability = sectionType == SectionType.liabilities;
    final context = ExecutionContext(
      idempotencyKey: 'opening-balance-${account.id}',
    );

    final result = await _engine.execute(
      OpeningBalanceOperation(
        intent: OpeningBalanceIntent(
          accountId: account.id,
          amount: balance,
          isLiability: isLiability,
        ),
        metadata: TransactionMetadata(
          occurredAt: DateTime.now(),
          note: 'Initial balance',
          paymentMethod: paymentMethod,
          currencyCode: currency,
        ),
        context: context,
      ),
      context,
    );

    if (result is! OperationSucceeded) {
      throw StateError('Opening balance operation failed: $result');
    }
  }

  Future<void> createBalanceAdjustment({
    required String accountId,
    required double oldBalance,
    required double newBalance,
    required String paymentMethod,
    required String currency,
  }) async {
    final difference = newBalance - oldBalance;

    if (difference == 0) return;

    throw UnsupportedError(
      'Balance adjustment must be executed through the Financial Operation Engine.',
    );
  }
}
