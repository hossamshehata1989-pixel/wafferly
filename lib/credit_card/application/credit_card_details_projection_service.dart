import 'package:hive_flutter/hive_flutter.dart';

import '../../core/money/money.dart';
import '../../credit_card/domain/credit_card_profile.dart';
import '../../credit_card/domain/credit_card_profile_repository.dart';
import '../../credit_card/infrastructure/hive_credit_card_profile_repository.dart';
import '../../financial_engine/ports/credit_card_balance_reader.dart';
import '../../infrastructure/hive/hive_balance_port.dart';
import '../../constants/transaction_constants.dart';
import '../../models/financing/financing_contract.dart';
import '../../models/financing/financing_installment.dart';
import '../../models/transaction.dart';
import '../../services/transaction_query_service.dart';
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
    required this.transactions,
    required this.installments,
    required this.totalInstallment,
    required this.thisMonthInstallment,
    required this.overdueDays,
  });

  final Account account;
  final CreditCardProfile profile;
  final Money outstanding;
  final Money available;
  final double utilization;
  final List<Transaction> transactions;
  final List<FinancingInstallment> installments;
  final Money totalInstallment;
  final Money thisMonthInstallment;
  final int overdueDays;
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
    TransactionQueryService? transactionQueryService,
  })  : _accountService = accountService ?? AccountService(),
        _profileRepository = profileRepository ??
            HiveCreditCardProfileRepository(
              Hive.box<CreditCardProfile>('credit_card_profiles'),
            ),
        _balanceReader = balanceReader ??
            HiveBalancePort(balanceService: BalanceService()),
        _transactionQueryService = transactionQueryService ??
            const TransactionQueryService();

  final AccountService _accountService;
  final CreditCardProfileRepository _profileRepository;
  final CreditCardBalanceReader _balanceReader;
  final TransactionQueryService _transactionQueryService;

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

    final transactions = _transactionQueryService
        .getForAccount(accountId)
        .where((tx) => tx.type == TransactionType.creditCardCharge)
        .toList(growable: false);

    final installmentBox = Hive.box<FinancingInstallment>('financing_installments');
    final contractBox = Hive.box<FinancingContract>('financing_contracts');
    final installments = installmentBox.values
        .where((item) => contractBox.get(item.contractId)?.liabilityAccountId == accountId)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final now = DateTime.now();
    final thisMonthInstallment = installments
        .where((item) =>
            item.dueDate.year == now.year &&
            item.dueDate.month == now.month &&
            item.status != 'settled')
        .fold(Money.zero, (sum, item) => sum + item.amount);

    final totalInstallment = installments
        .where((item) => item.status != 'settled')
        .fold(Money.zero, (sum, item) => sum + item.amount);

    var overdueDays = 0;
    for (final item in installments) {
      if (item.status == 'settled' || !item.dueDate.isBefore(now)) continue;
      final days = now.difference(item.dueDate).inDays;
      if (days > overdueDays) overdueDays = days;
    }

    return CreditCardDetailsProjection(
      account: account,
      profile: profile,
      outstanding: outstanding,
      available: available,
      utilization: utilization,
      transactions: transactions,
      installments: installments,
      totalInstallment: totalInstallment,
      thisMonthInstallment: thisMonthInstallment,
      overdueDays: overdueDays,
    );
  }
}
