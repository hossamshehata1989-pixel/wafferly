import 'package:flutter/foundation.dart';

import '../core/money/money.dart';
import '../models/account.dart';
import '../models/enums/account_enums.dart';
import 'account_service.dart';
import 'balance_service.dart';

final class LiabilityCategoryReadModel {
  const LiabilityCategoryReadModel({
    required this.accounts,
    required this.outstandingByCurrency,
  });

  final List<Account> accounts;

  /// Portfolio outstanding totals grouped by their original account currency.
  /// Never add amounts denominated in different currencies together.
  final Map<String, Money> outstandingByCurrency;

}

/// Read-only application service for liability screens.
///
/// Account filtering and currency-aware liability totals live here so the
/// presentation layer never combines balances denominated in different units.
final class LiabilityReadService {
  LiabilityReadService({
    AccountService? accountService,
    BalanceService? balanceService,
  })  : _accountService = accountService ?? AccountService(),
        _balanceService = balanceService ?? BalanceService();

  final AccountService _accountService;
  final BalanceService _balanceService;

  Listenable get listenable => _accountService.accountsListenable;

  List<Account> getActiveLiabilities() => _accountService
      .getAllActiveAccounts()
      .where((account) => account.group == AccountGroup.liabilities)
      .toList();

  LiabilityCategoryReadModel getCategory({required Set<String> types}) {
    final accounts = getActiveLiabilities()
        .where((account) => types.contains(account.type))
        .toList();

    final outstandingByCurrency = <String, Money>{};
    for (final account in accounts) {
      final currency = account.currency.trim().isEmpty
          ? 'Unknown currency'
          : account.currency.trim();
      final outstanding = outstandingFor(account.id);
      outstandingByCurrency[currency] =
          (outstandingByCurrency[currency] ?? Money.zero) + outstanding;
    }

    return LiabilityCategoryReadModel(
      accounts: List.unmodifiable(accounts),
      outstandingByCurrency: Map.unmodifiable(outstandingByCurrency),
    );
  }

  Money outstandingFor(String accountId) {
    final balance = _balanceService.getBalance(accountId);
    return balance < 0 ? Money.fromDouble(-balance) : Money.zero;
  }

  Account? getAccount(String accountId) => _accountService.getAccountById(accountId);
}
