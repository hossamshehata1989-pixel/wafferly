import '../../credit_card/domain/credit_card_profile.dart';
import '../../models/account.dart';
import '../../models/enums/account_enums.dart';
import '../../services/account_service.dart';
import '../../services/transaction_application_service.dart';
import '../../core/money/money.dart';
import '../../financial_engine/results/operation_result.dart';

/// Application boundary for choosing an eligible source and executing a
/// Credit Card settlement through TransactionApplicationService / the engine.
final class CreditCardPaymentApplicationService {
  CreditCardPaymentApplicationService({
    required TransactionApplicationService transactionApplicationService,
    AccountService? accountService,
  }) : _transactions = transactionApplicationService,
       _accounts = accountService ?? AccountService();

  final TransactionApplicationService _transactions;
  final AccountService _accounts;

  /// Active same-book, same-currency asset accounts. The card's linked bank
  /// account is listed first when it remains eligible (ADR-072).
  List<Account> eligiblePaymentSources({
    required Account creditCardAccount,
    required CreditCardProfile profile,
  }) {
    final result = _accounts.getAllActiveAccounts().where((account) {
      return account.id != creditCardAccount.id &&
          !account.isArchived &&
          account.nature == AccountNature.asset &&
          account.bookId == creditCardAccount.bookId &&
          account.currency == creditCardAccount.currency;
    }).toList();

    final linkedId = profile.linkedBankAccountId;
    result.sort((a, b) {
      if (a.id == linkedId && b.id != linkedId) return -1;
      if (b.id == linkedId && a.id != linkedId) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return result;
  }

  Future<OperationResult> pay({
    required String sourceAssetAccountId,
    required Account creditCardAccount,
    required Money amount,
    required DateTime occurredAt,
    required String note,
    required String idempotencyKey,
    String? actorMemberId,
  }) {
    return _transactions.addCreditCardPayment(
      sourceAssetAccountId: sourceAssetAccountId,
      creditCardAccountId: creditCardAccount.id,
      amount: amount,
      occurredAt: occurredAt,
      note: note,
      idempotencyKey: idempotencyKey,
      actorMemberId: actorMemberId,
    );
  }
}
