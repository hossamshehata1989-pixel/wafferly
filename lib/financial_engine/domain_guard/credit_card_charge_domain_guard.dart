import '../../core/money/money.dart';
import '../../credit_card/domain/credit_card_profile_repository.dart';
import '../../models/enums/account_enums.dart';
import '../../services/account_service.dart';
import '../interpretation/financial_action_type.dart';
import '../ports/credit_card_balance_reader.dart';
import '../interpretation/normalized_intent.dart';
import 'domain_guard.dart';
import 'domain_guard_result.dart';

/// Validates Credit Card charge-specific rules.
///
/// Unlike [BalanceDomainGuard], this guard never asks whether cash is
/// available. It validates the liability's credit exposure against the
/// Credit Card profile's limit.
final class CreditCardChargeDomainGuard implements DomainGuard {
  final AccountService _accountService;
  final CreditCardProfileRepository _profileRepository;
  final CreditCardBalanceReader _balanceReader;

  const CreditCardChargeDomainGuard({
    required AccountService accountService,
    required CreditCardProfileRepository profileRepository,
    required CreditCardBalanceReader balanceReader,
  }) : _accountService = accountService,
       _profileRepository = profileRepository,
       _balanceReader = balanceReader;

  @override
  Future<DomainGuardResult> validate(NormalizedIntent intent) async {
    if (intent.action != FinancialActionType.creditCardCharge) {
      return const DomainGuardPassed();
    }

    if (intent.sourceAccountId.trim().isEmpty) {
      return const DomainViolation(
        reason: 'Credit Card account is required.',
      );
    }

    if (intent.amount <= Money.zero) {
      return const DomainViolation(
        reason: 'Credit Card charge amount must be greater than zero.',
      );
    }

    final account = _accountService.getById(intent.sourceAccountId);
    if (account == null) {
      return const DomainViolation(reason: 'Credit Card account was not found.');
    }

    if (account.isArchived) {
      return const DomainViolation(
        reason: 'The Credit Card account is archived and cannot be used.',
      );
    }

    if (account.nature != AccountNature.liability) {
      return const DomainViolation(
        reason: 'Credit Card charges require a liability account.',
      );
    }

    final profile = await _profileRepository.findByAccountId(
      intent.sourceAccountId,
    );
    if (profile == null) {
      return const DomainViolation(
        reason: 'Credit Card profile was not found for the account.',
      );
    }

    final currentLiabilityBalance =
        await _balanceReader.currentBalance(intent.sourceAccountId);

    // Liability balances are represented as signed negative balances in the
    // existing financial truth model. A positive balance therefore does not
    // consume credit capacity.
    final currentExposure = currentLiabilityBalance.isNegative
        ? -currentLiabilityBalance
        : Money.zero;
    final resultingExposure = currentExposure + intent.amount;

    if (resultingExposure > profile.creditLimit) {
      return DomainViolation(
        reason:
            'Credit limit exceeded. Available: '
            '${profile.creditLimit - currentExposure}, '
            'required: ${intent.amount}.',
      );
    }

    return const DomainGuardPassed();
  }
}

