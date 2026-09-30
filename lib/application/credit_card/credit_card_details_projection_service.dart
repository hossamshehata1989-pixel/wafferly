import 'package:hive_flutter/hive_flutter.dart';

import '../../core/money/money.dart';
import '../../credit_card/domain/credit_card_profile.dart';
import '../../credit_card/domain/credit_card_profile_repository.dart';
import '../../credit_card/infrastructure/hive_credit_card_profile_repository.dart';
import '../../financial_engine/ports/credit_card_balance_reader.dart';
import '../../infrastructure/hive/hive_balance_port.dart';
import '../../models/account.dart';
import '../../services/account_service.dart';
import '../../services/balance_service.dart';

final class CreditCardDetailsProjection {
  const CreditCardDetailsProjection({
    required this.account,
    required this.profile,
    required this.outstanding,
    required this.available,
    required this.utilization,
  });

  final Account account;
  final CreditCardProfile profile;
  final Money outstanding;
  final Money available;
  final double utilization;
}

/// Read-only application projection for the Credit Card details screen.
///
/// The screen receives prepared state; it does not access Hive or calculate
/// financial exposure itself. Liability balance remains authoritative.
final class CreditCardDetailsProjectionService {
  CreditCardDetailsProjectionService({
    AccountService? accountService,
    CreditCardProfileRepository? profileRepository,
    CreditCardBalanceReader? balanceReader,
  })  : _accountService = accountService ?? AccountService(),
        _profileRepository = profileRepository ??
            HiveCreditCardProfileRepository(
              Hive.box<CreditCardProfile>('credit_card_profiles'),
            ),
        _balanceReader = balanceReader ??
            HiveBalancePort(balanceService: BalanceService());

  final AccountService _accountService;
  final CreditCardProfileRepository _profileRepository;
  final CreditCardBalanceReader _balanceReader;

  Future<CreditCardDetailsProjection?> project(String accountId) async {
    final account = _accountService.getAccountById(accountId);
    if (account == null || account.isArchived || account.type != 'creditCard') {
      return null;
    }

    final profile = await _profileRepository.findByAccountId(accountId);
    if (profile == null) return null;

    final balance = await _balanceReader.currentBalance(accountId);
    final outstanding = balance.isNegative ? -balance : Money.zero;
    final available = profile.creditLimit > outstanding
        ? profile.creditLimit - outstanding
        : Money.zero;
    final limit = profile.creditLimit.toDouble();
    final exposure = outstanding.toDouble();
    final utilization = limit <= 0
        ? 0.0
        : (exposure / limit).clamp(0.0, 1.0).toDouble();

    return CreditCardDetailsProjection(
      account: account,
      profile: profile,
      outstanding: outstanding,
      available: available,
      utilization: utilization,
    );
  }
}
