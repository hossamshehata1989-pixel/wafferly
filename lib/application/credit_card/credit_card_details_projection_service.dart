import 'package:hive_flutter/hive_flutter.dart';

import '../../constants/transaction_constants.dart';
import '../../core/money/money.dart';
import '../../credit_card/domain/credit_card_profile.dart';
import '../../credit_card/domain/credit_card_profile_repository.dart';
import '../../credit_card/infrastructure/hive_credit_card_profile_repository.dart';
import '../../financial_engine/ports/credit_card_balance_reader.dart';
import '../../infrastructure/hive/hive_balance_port.dart';
import '../../models/account.dart';
import '../../models/financing/financing_contract.dart';
import '../../models/financing/financing_installment.dart';
import '../../models/transaction.dart';
import '../../services/account_service.dart';
import '../../services/balance_service.dart';
import '../../services/transaction_query_service.dart';

final class CreditCardDetailsProjection {
  const CreditCardDetailsProjection({
    required this.account,
    required this.profile,
    required this.outstanding,
    required this.available,
    required this.utilization,
    required this.transactions,
    required this.installments,
    required this.convertedChargeIds,
  });

  final Account account;
  final CreditCardProfile profile;
  final Money outstanding;
  final Money available;
  final double utilization;

  /// Prepared read-model data for the details screen.
  /// The screen must not query Hive directly.
  final List<Transaction> transactions;
  final List<FinancingInstallment> installments;
  final Set<String> convertedChargeIds;
}

/// Read-only application projection for the Credit Card details screen.
///
/// Storage access and financial read-model preparation stay at the application
/// boundary. The screen receives prepared state and only renders it.
final class CreditCardDetailsProjectionService {
  CreditCardDetailsProjectionService({
    AccountService? accountService,
    CreditCardProfileRepository? profileRepository,
    CreditCardBalanceReader? balanceReader,
    TransactionQueryService? transactionQueryService,
    Box<FinancingInstallment>? installmentBox,
    Box<FinancingContract>? contractBox,
  })  : _accountService = accountService ?? AccountService(),
        _profileRepository = profileRepository ??
            HiveCreditCardProfileRepository(
              Hive.box<CreditCardProfile>('credit_card_profiles'),
            ),
        _balanceReader = balanceReader ??
            HiveBalancePort(balanceService: BalanceService()),
        _transactionQueryService =
            transactionQueryService ?? const TransactionQueryService(),
        _installmentBox =
            installmentBox ?? Hive.box<FinancingInstallment>('financing_installments'),
        _contractBox =
            contractBox ?? Hive.box<FinancingContract>('financing_contracts');

  final AccountService _accountService;
  final CreditCardProfileRepository _profileRepository;
  final CreditCardBalanceReader _balanceReader;
  final TransactionQueryService _transactionQueryService;
  final Box<FinancingInstallment> _installmentBox;
  final Box<FinancingContract> _contractBox;

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
        .toList();

    final contracts = _contractBox.values.where((contract) {
      final state = contract.lifecycleState.trim().toLowerCase();
      return contract.liabilityAccountId == accountId &&
          state != 'cancelled' &&
          state != 'terminated';
    }).toList();

    final contractIds = contracts.map((contract) => contract.contractId).toSet();
    final installments = _installmentBox.values
        .where((item) => contractIds.contains(item.contractId))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final transactionIds = transactions.map((tx) => tx.id).toSet();
    final convertedChargeIds = contracts
        .map((contract) => contract.originReference)
        .where(transactionIds.contains)
        .toSet();

    return CreditCardDetailsProjection(
      account: account,
      profile: profile,
      outstanding: outstanding,
      available: available,
      utilization: utilization,
      transactions: transactions,
      installments: installments,
      convertedChargeIds: convertedChargeIds,
    );
  }
}
