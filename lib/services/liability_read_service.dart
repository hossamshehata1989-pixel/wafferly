import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../core/money/money.dart';
import '../models/account.dart';
import '../models/commitment.dart';
import '../models/enums/account_enums.dart';
import '../models/schedule_occurrence.dart';
import '../models/schedule_rule.dart';
import 'account_service.dart';
import 'balance_service.dart';
import 'debt_query_service.dart';

final class LiabilityCategoryReadModel {
  const LiabilityCategoryReadModel({
    required this.accounts,
    required this.totalOutstanding,
  });

  final List<Account> accounts;
  final Money totalOutstanding;
}

/// Read-only application service for liability screens.
///
/// Account filtering remains here, while all category-level liability totals
/// are derived by DebtQueryService. This keeps debt aggregation in one read
/// model instead of duplicating it in presentation/services.
final class LiabilityReadService {
  LiabilityReadService({
    AccountService? accountService,
    BalanceService? balanceService,
    DebtQueryService? debtQueryService,
  })  : _accountService = accountService ?? AccountService(),
        _balanceService = balanceService ?? BalanceService(),
        _debtQueryService = debtQueryService ?? _buildDebtQueryService();

  final AccountService _accountService;
  final BalanceService _balanceService;
  final DebtQueryService _debtQueryService;

  static DebtQueryService _buildDebtQueryService() {
    return DebtQueryService(
      balanceService: BalanceService(),
      accountBox: Hive.box<Account>('accounts'),
      commitmentBox: Hive.box<Commitment>('commitments'),
      scheduleRuleBox: Hive.box<ScheduleRule>('schedule_rules'),
      occurrenceBox: Hive.box<ScheduleOccurrence>('schedule_occurrences'),
    );
  }

  Listenable get listenable => _accountService.accountsListenable;

  List<Account> getActiveLiabilities() => _accountService
      .getAllActiveAccounts()
      .where((account) => account.group == AccountGroup.liabilities)
      .toList();

  LiabilityCategoryReadModel getCategory({required Set<String> types}) {
    final accounts = getActiveLiabilities()
        .where((account) => types.contains(account.type))
        .toList();

    final summary = _debtQueryService.getCategorySummary(
      types: types,
      title: 'Liability',
      today: DateTime.now(),
    );

    return LiabilityCategoryReadModel(
      accounts: List.unmodifiable(accounts),
      totalOutstanding: summary.outstanding,
    );
  }

  Money outstandingFor(String accountId) {
    final balance = _balanceService.getBalance(accountId);
    return balance < 0 ? Money.fromDouble(-balance) : Money.zero;
  }

  Account? getAccount(String accountId) => _accountService.getAccountById(accountId);
}
