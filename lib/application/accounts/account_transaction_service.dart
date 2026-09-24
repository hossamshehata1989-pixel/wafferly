import 'package:wafferly/financial_engine/commands/opening_balance/opening_balance_intent.dart';
import 'package:wafferly/financial_engine/commands/balance_reconciliation/balance_reconciliation_intent.dart';
import 'package:wafferly/financial_engine/commands/balance_reconciliation/reconciliation_reason.dart';
import 'package:wafferly/financial_engine/commands/shared/transaction_metadata.dart';
import 'package:wafferly/financial_engine/engine/financial_operation_engine.dart';
import 'package:wafferly/financial_engine/execution_context/execution_context.dart';
import 'package:wafferly/financial_engine/ports/balance_port.dart';
import 'package:wafferly/financial_engine/operations/opening_balance_operation.dart';
import 'package:wafferly/financial_engine/operations/balance_reconciliation_operation.dart';
import 'package:wafferly/financial_engine/results/operation_result.dart';
import 'package:wafferly/models/account.dart';
import 'package:wafferly/models/enums/account_enums.dart';
import 'package:wafferly/services/account_service.dart';
import 'package:wafferly/models/enums/section_type.dart';

class AccountTransactionService {
  final FinancialOperationEngine _engine;
  final BalancePort _balancePort;
  final AccountService _accountService;

  const AccountTransactionService({
    required FinancialOperationEngine engine,
    required BalancePort balancePort,
    required AccountService accountService,
  }) : _engine = engine,
       _balancePort = balancePort,
       _accountService = accountService;

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

  /// Reconciles an observed account balance against the balance currently
  /// derived by Wafferly. The supplied [oldBalance] is retained for API
  /// compatibility only; the engine uses the current derived balance as the
  /// source of truth.
  Future<void> createBalanceReconciliation({
    required String accountId,
    required double observedBalance,
    required String paymentMethod,
    required String currency,
    ReconciliationReason reason = ReconciliationReason.other,
    String? idempotencyKey,
  }) async {
    final account = _accountService.getAccountById(accountId);
    if (account == null) {
      throw StateError('Account not found: $accountId');
    }

    final systemBalance =
        await _balancePort.currentBalance(accountId);

    if (systemBalance == observedBalance) return;

    final context = ExecutionContext(
      idempotencyKey: idempotencyKey ??
          'balance-reconciliation-$accountId-${DateTime.now().microsecondsSinceEpoch}',
    );

    final result = await _engine.execute(
      BalanceReconciliationOperation(
        intent: BalanceReconciliationIntent(
          accountId: accountId,
          systemBalance: systemBalance,
          observedBalance: observedBalance,
          isLiability: account.nature == AccountNature.liability,
          reason: reason,
        ),
        metadata: TransactionMetadata(
          occurredAt: DateTime.now(),
          note: 'Balance reconciliation',
          paymentMethod: paymentMethod,
          currencyCode: currency,
        ),
        context: context,
      ),
      context,
    );

    if (result is! OperationSucceeded) {
      throw StateError('Balance reconciliation operation failed: $result');
    }
  }

  /// Legacy name retained temporarily for callers that still refer to
  /// "Balance Adjustment". It now delegates to the canonical
  /// Balance Reconciliation operation and never mutates Account balance.
  @Deprecated('Use createBalanceReconciliation instead.')
  Future<void> createBalanceAdjustment({
    required String accountId,
    required double oldBalance,
    required double newBalance,
    required String paymentMethod,
    required String currency,
  }) async {
    await createBalanceReconciliation(
      accountId: accountId,
      observedBalance: newBalance,
      paymentMethod: paymentMethod,
      currency: currency,
    );
  }
}
