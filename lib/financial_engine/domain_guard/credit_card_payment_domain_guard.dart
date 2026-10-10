import '../../core/money/money.dart';
import '../../credit_card/domain/credit_card_profile_repository.dart';
import '../../models/enums/account_enums.dart';
import '../../services/account_service.dart';
import '../interpretation/financial_action_type.dart';
import '../interpretation/normalized_intent.dart';
import '../ports/credit_card_balance_reader.dart';
import 'domain_guard.dart';
import 'domain_guard_result.dart';

/// Enforces the Credit Card payment/settlement boundary (ADR-051, ADR-072).
/// It validates the source, target, currency, linked profile, and settlement
/// amount before the Financial Engine plans any mutation.
final class CreditCardPaymentDomainGuard implements DomainGuard {
  final AccountService _accountService;
  final CreditCardProfileRepository _profileRepository;
  final CreditCardBalanceReader _balanceReader;

  const CreditCardPaymentDomainGuard({
    required AccountService accountService,
    required CreditCardProfileRepository profileRepository,
    required CreditCardBalanceReader balanceReader,
  }) : _accountService = accountService,
       _profileRepository = profileRepository,
       _balanceReader = balanceReader;

  @override
  Future<DomainGuardResult> validate(NormalizedIntent intent) async {
    if (intent.action != FinancialActionType.creditCardPayment) {
      return const DomainGuardPassed();
    }

    if (intent.sourceAccountId.trim().isEmpty) {
      return const DomainViolation(reason: 'A payment source account is required.');
    }
    final targetId = intent.destinationAccountId;
    if (targetId == null || targetId.trim().isEmpty) {
      return const DomainViolation(reason: 'A Credit Card account is required.');
    }
    if (intent.sourceAccountId == targetId) {
      return const DomainViolation(
        reason: 'The payment source and Credit Card account must be different.',
      );
    }
    if (intent.amount <= Money.zero) {
      return const DomainViolation(
        reason: 'Credit Card payment amount must be greater than zero.',
      );
    }

    final source = _accountService.getById(intent.sourceAccountId);
    if (source == null) {
      return const DomainViolation(reason: 'Payment source account was not found.');
    }
    if (source.isArchived) {
      return const DomainViolation(
        reason: 'The payment source account is archived and cannot be used.',
      );
    }
    if (source.nature != AccountNature.asset) {
      return const DomainViolation(
        reason: 'Credit Card payments must come from an Asset Account.',
      );
    }

    final card = _accountService.getById(targetId);
    if (card == null) {
      return const DomainViolation(reason: 'Credit Card account was not found.');
    }
    if (card.isArchived) {
      return const DomainViolation(
        reason: 'The Credit Card account is archived and cannot be paid.',
      );
    }
    if (card.nature != AccountNature.liability || card.type != 'creditCard') {
      return const DomainViolation(
        reason: 'The target must be an active Credit Card liability account.',
      );
    }
    if (source.bookId != card.bookId) {
      return const DomainViolation(
        reason: 'Payment source and Credit Card must belong to the same book.',
      );
    }
    if (source.currency != card.currency) {
      return const DomainViolation(
        reason: 'Credit Card payments between different currencies are not supported yet.',
      );
    }
    if (intent.currencyCode != null && intent.currencyCode != source.currency) {
      return const DomainViolation(
        reason: 'Payment currency must match the source and Credit Card account currencies.',
      );
    }

    final profile = await _profileRepository.findByAccountId(targetId);
    if (profile == null || profile.accountId != targetId) {
      return const DomainViolation(
        reason: 'A matching Credit Card profile is required for settlement.',
      );
    }

    // Liability balances are signed negative. Treat only a negative current
    // balance as outstanding liability; a credit balance cannot be paid again.
    final currentBalance = await _balanceReader.currentBalance(targetId);
    final outstanding = currentBalance.isNegative ? -currentBalance : Money.zero;
    if (intent.amount > outstanding) {
      return DomainViolation(
        reason:
            'Payment exceeds the current outstanding liability. '
            'Outstanding: $outstanding, requested: ${intent.amount}.',
      );
    }

    return const DomainGuardPassed();
  }
}
