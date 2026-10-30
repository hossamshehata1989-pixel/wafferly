import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../core/money/money.dart';
import '../../models/transaction.dart';
import '../commands/shared/transaction_metadata.dart';
import '../domain/financial_transaction_record.dart';
import '../execution_context/execution_context.dart';
import '../operations/balance_reconciliation_operation.dart';
import '../operations/commitment_payment_operation.dart';
import '../operations/correction_financial_operation.dart';
import '../operations/create_goal_allocation_operation.dart';
import '../operations/credit_card_charge_operation.dart';
import '../operations/credit_card_payment_operation.dart';
import '../operations/deletion_operation.dart';
import '../operations/expense_operation.dart';
import '../operations/financial_operation.dart';
import '../operations/goal_saving_transfer_operation.dart';
import '../operations/goal_transfer_operation.dart';
import '../operations/income_operation.dart';
import '../operations/opening_balance_operation.dart';
import '../operations/transfer_operation.dart';
import '../resolution/resolution.dart';

/// Produces a deterministic SHA-256 fingerprint for a financial request.
///
/// The fingerprint is built from the original FinancialOperation, not from
/// NormalizedIntent. The interpreter intentionally drops some command and
/// metadata fields, so NormalizedIntent is not a sufficient request identity.
///
/// Map fields are authored in a fixed order. Nullable values remain explicit
/// JSON nulls, and monetary values are serialized as exact decimal strings.
final class FinancialOperationFingerprint {
  const FinancialOperationFingerprint._();

  static String compute({
    required FinancialOperation operation,
    required ExecutionContext executionContext,
  }) {
    final operationContext = _contextOf(operation);

    if (operationContext.idempotencyKey != executionContext.idempotencyKey) {
      throw ArgumentError(
        'The FinancialOperation context idempotency key must match the '
        'FinancialOperationEngine execution context key.',
      );
    }

    final canonicalRequest = <String, Object?>{
      'schema': 'wafferly.financial-operation-request.v1',
      'operationType': _operationType(operation),
      'resolution': (operation.resolution ?? Resolution.execute).name,
      'operation': _operationData(operation),
      // Both contexts are included because the operation context is consumed
      // by planning while the external context is consumed by traceability.
      // The idempotency key itself is the lookup key and is not hashed.
      'operationContext': _contextData(operationContext),
      'executionContext': _contextData(executionContext),
    };

    final canonicalJson = jsonEncode(canonicalRequest);
    return sha256.convert(utf8.encode(canonicalJson)).toString();
  }

  /// Stable discriminator persisted indirectly through the fingerprint.
  /// Do not replace these values with runtimeType.toString(): runtime class
  /// names may change during refactors or release obfuscation.
  static String _operationType(FinancialOperation operation) {
    return switch (operation) {
      BalanceReconciliationOperation() => 'balance_reconciliation',
      CommitmentPaymentOperation() => 'commitment_payment',
      CorrectionOperation() => 'correction',
      CreateGoalAllocationOperation() => 'create_goal_allocation',
      CreditCardChargeOperation() => 'credit_card_charge',
      CreditCardPaymentOperation() => 'credit_card_payment',
      DeleteOperation() => 'deletion',
      ExpenseOperation() => 'expense',
      GoalSavingTransferOperation() => 'goal_saving_transfer',
      GoalTransferOperation() => 'goal_transfer',
      IncomeOperation() => 'income',
      OpeningBalanceOperation() => 'opening_balance',
      TransferOperation() => 'transfer',
      _ => throw UnsupportedError(
        'No idempotency fingerprint contract exists for '
        '${operation.runtimeType}.',
      ),
    };
  }

  static ExecutionContext _contextOf(FinancialOperation operation) {
    return switch (operation) {
      BalanceReconciliationOperation value => value.context,
      CommitmentPaymentOperation value => value.context,
      CorrectionOperation value => value.context,
      CreateGoalAllocationOperation value => value.context,
      CreditCardChargeOperation value => value.context,
      CreditCardPaymentOperation value => value.context,
      DeleteOperation value => value.context,
      ExpenseOperation value => value.context,
      GoalSavingTransferOperation value => value.context,
      GoalTransferOperation value => value.context,
      IncomeOperation value => value.context,
      OpeningBalanceOperation value => value.context,
      TransferOperation value => value.context,
      _ => throw UnsupportedError(
        'No idempotency fingerprint contract exists for '
        '${operation.runtimeType}.',
      ),
    };
  }

  static Map<String, Object?> _operationData(FinancialOperation operation) {
    return switch (operation) {
      BalanceReconciliationOperation value => <String, Object?>{
        'accountId': value.intent.accountId,
        'systemBalance': _money(value.intent.systemBalance),
        'observedBalance': _money(value.intent.observedBalance),
        'isLiability': value.intent.isLiability,
        'reason': value.intent.reason.name,
        'metadata': _metadataData(value.metadata),
      },
      CommitmentPaymentOperation value => <String, Object?>{
        'sourceAccountId': value.sourceAccountId,
        'liabilityAccountId': value.liabilityAccountId,
        'commitmentId': value.commitmentId,
        'amount': _money(value.amount),
        'metadata': _metadataData(value.metadata),
      },
      CorrectionOperation value => <String, Object?>{
        'transactionId': value.intent.transactionId,
        'before': _financialTransactionData(value.intent.before),
        'after': _financialTransactionData(value.intent.after),
        'metadata': _metadataData(value.metadata),
      },
      CreateGoalAllocationOperation value => <String, Object?>{
        'accountId': value.accountId,
        'goalId': value.goalId,
        'amount': _money(value.amount),
        'occurredAt': _dateTimeData(value.occurredAt),
        'metadata': _metadataData(value.metadata),
      },
      CreditCardChargeOperation value => <String, Object?>{
        'creditCardAccountId': value.intent.creditCardAccountId,
        'categoryId': value.intent.categoryId,
        'subCategoryId': value.intent.subCategoryId,
        'amount': _money(value.intent.amount),
        'isExceptional': value.intent.isExceptional,
        'actorMemberId': value.intent.actorMemberId,
        'metadata': _metadataData(value.metadata),
      },
      CreditCardPaymentOperation value => <String, Object?>{
        'sourceAssetAccountId': value.sourceAssetAccountId,
        'creditCardAccountId': value.creditCardAccountId,
        'amount': _money(value.amount),
        'metadata': _metadataData(value.metadata),
      },
      DeleteOperation value => <String, Object?>{
        'transaction': _transactionData(value.intent.transaction),
        'metadata': _metadataData(value.metadata),
      },
      ExpenseOperation value => <String, Object?>{
        'sourceAccountId': value.intent.sourceAccountId,
        'amount': _money(value.intent.amount),
        'categoryId': value.intent.categoryId,
        'isExceptional': value.intent.isExceptional,
        'actorMemberId': value.intent.actorMemberId,
        'metadata': _metadataData(value.metadata),
      },
      GoalSavingTransferOperation value => <String, Object?>{
        'sourceAccountId': value.sourceAccountId,
        'savingsAccountId': value.savingsAccountId,
        'goalId': value.goalId,
        'amount': _money(value.amount),
        'metadata': _metadataData(value.metadata),
      },
      GoalTransferOperation value => <String, Object?>{
        'sourceAccountId': value.sourceAccountId,
        'savingsAccountId': value.savingsAccountId,
        'goalId': value.goalId,
        'amount': _money(value.amount),
        'metadata': _metadataData(value.metadata),
      },
      IncomeOperation value => <String, Object?>{
        'sourceAccountId': value.intent.sourceAccountId,
        'amount': _money(value.intent.amount),
        'categoryId': value.intent.categoryId,
        'isExceptional': value.intent.isExceptional,
        'actorMemberId': value.intent.actorMemberId,
        'metadata': _metadataData(value.metadata),
      },
      OpeningBalanceOperation value => <String, Object?>{
        'accountId': value.intent.accountId,
        'amount': _money(value.intent.amount),
        'isLiability': value.intent.isLiability,
        'metadata': _metadataData(value.metadata),
      },
      TransferOperation value => <String, Object?>{
        'fromAccountId': value.intent.fromAccountId,
        'toAccountId': value.intent.toAccountId,
        'amount': _money(value.intent.amount),
        'metadata': _metadataData(value.metadata),
      },
      _ => throw UnsupportedError(
        'No idempotency fingerprint contract exists for '
        '${operation.runtimeType}.',
      ),
    };
  }

  static Map<String, Object?> _contextData(ExecutionContext context) =>
      <String, Object?>{
        'commitmentId': context.commitmentId,
        'scheduleRuleId': context.scheduleRuleId,
        'occurrenceId': context.occurrenceId,
        'actorMemberId': context.actorMemberId,
        'source': context.source,
        'commandType': context.commandType,
      };

  static Map<String, Object?> _metadataData(TransactionMetadata metadata) =>
      <String, Object?>{
        'occurredAt': _dateTimeData(metadata.occurredAt),
        'note': metadata.note,
        'paymentMethod': metadata.paymentMethod,
        'currencyCode': metadata.currencyCode,
      };

  static Map<String, Object?> _financialTransactionData(
    FinancialTransactionRecord value,
  ) => <String, Object?>{
    'transactionId': value.transactionId,
    'type': value.type,
    'fromAccountId': value.fromAccountId,
    'toAccountId': value.toAccountId,
    'categoryId': value.categoryId,
    'subCategoryId': value.subCategoryId,
    'amount': _money(value.amount),
    'currencyCode': value.currencyCode,
    'paymentMethod': value.paymentMethod,
    'occurredAt': _dateTimeData(value.occurredAt),
    'note': value.note,
    'isExceptional': value.isExceptional,
    'source': value.source,
    'actorMemberId': value.actorMemberId,
    'commitmentId': value.commitmentId,
    'scheduleRuleId': value.scheduleRuleId,
    'occurrenceId': value.occurrenceId,
  };

  static Map<String, Object?> _transactionData(Transaction value) =>
      <String, Object?>{
        'id': value.id,
        'amount': _money(Money.fromDouble(value.amount)),
        'type': value.type,
        'fromAccountId': value.fromAccountId,
        'toAccountId': value.toAccountId,
        'categoryId': value.categoryId,
        'date': _dateTimeData(value.date),
        'note': value.note,
        'paymentMethod': value.paymentMethod,
        'isExceptional': value.isExceptional,
        'subCategoryId': value.subCategoryId,
        'currencyCode': value.currencyCode,
        'source': value.source,
        'createdAt': _dateTimeData(value.createdAt),
        'updatedAt': _dateTimeData(value.updatedAt),
        'actorMemberId': value.actorMemberId,
        'commitmentId': value.commitmentId,
        'scheduleRuleId': value.scheduleRuleId,
        'occurrenceId': value.occurrenceId,
      };

  static String _money(Money value) => value.toString();

  static Map<String, Object?> _dateTimeData(DateTime value) =>
      <String, Object?>{'value': value.toIso8601String(), 'isUtc': value.isUtc};
}
