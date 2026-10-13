import 'package:hive_flutter/hive_flutter.dart';

import '../../constants/transaction_constants.dart';
import '../../credit_card/domain/credit_card_profile.dart';
import '../../models/account.dart';
import '../../models/financing/financing_contract.dart';
import '../../models/financing/financing_installment.dart';
import '../../models/transaction.dart';
import '../../services/transaction_query_service.dart';
import 'credit_card_cycle_resolver.dart';

/// Read-only projection of credit-card spending into the calendar month in
/// which it should be reported as an expense.
///
/// Credit-card charges remain the authoritative financial records. These
/// synthetic expense transactions are only used by reports; they are never
/// written to Hive and must not be used for balance/ledger calculations.
final class CreditCardExpenseProjectionService {
  CreditCardExpenseProjectionService({
    TransactionQueryService? transactionQueryService,
    Box<Account>? accountsBox,
    Box<CreditCardProfile>? profilesBox,
    Box<FinancingContract>? contractsBox,
    Box<FinancingInstallment>? installmentsBox,
  })  : _transactionQueryService =
            transactionQueryService ?? const TransactionQueryService(),
        _accountsBox = accountsBox,
        _profilesBox = profilesBox,
        _contractsBox = contractsBox,
        _installmentsBox = installmentsBox;

  final TransactionQueryService _transactionQueryService;
  final Box<Account>? _accountsBox;
  final Box<CreditCardProfile>? _profilesBox;
  final Box<FinancingContract>? _contractsBox;
  final Box<FinancingInstallment>? _installmentsBox;

  Box<T>? _box<T>(Box<T>? supplied, String name) {
    if (supplied != null) return supplied;
    if (!Hive.isBoxOpen(name)) return null;
    return Hive.box<T>(name);
  }

  /// Returns report-only expense rows whose recognition date is in [startDate]
  /// through [endDate], inclusive. The underlying charge/installment records
  /// are read across all dates because an older purchase can be due this month.
  List<Transaction> projectForDateRange({
    required DateTime startDate,
    required DateTime endDate,
    DateTime? asOf,
  }) {
    final accountBox = _box(_accountsBox, 'accounts');
    if (accountBox == null) return <Transaction>[];

    final profileBox = _box(_profilesBox, 'credit_card_profiles');
    final contractBox = _box(_contractsBox, 'financing_contracts');
    final installmentBox = _box(_installmentsBox, 'financing_installments');

    return projectFromData(
      transactions: _transactionQueryService.getAllTransactions(),
      accounts: accountBox.values,
      profiles: profileBox?.values ?? const <CreditCardProfile>[],
      contracts: contractBox?.values ?? const <FinancingContract>[],
      installments: installmentBox?.values ?? const <FinancingInstallment>[],
      startDate: startDate,
      endDate: endDate,
      asOf: asOf ?? DateTime.now(),
    );
  }

  /// Pure projection seam for deterministic tests.
  static List<Transaction> projectFromData({
    required Iterable<Transaction> transactions,
    required Iterable<Account> accounts,
    required Iterable<CreditCardProfile> profiles,
    required Iterable<FinancingContract> contracts,
    required Iterable<FinancingInstallment> installments,
    required DateTime startDate,
    required DateTime endDate,
    required DateTime asOf,
  }) {
    final accountById = <String, Account>{
      for (final account in accounts)
        if (account.type == 'creditCard')
          account.id: account,
    };
    if (accountById.isEmpty) return <Transaction>[];

    final profileByAccountId = <String, CreditCardProfile>{
      for (final profile in profiles)
        if (accountById.containsKey(profile.accountId)) profile.accountId: profile,
    };

    final allCharges = transactions
        .where((tx) =>
            tx.type == TransactionType.creditCardCharge &&
            tx.toAccountId != null &&
            accountById.containsKey(tx.toAccountId))
        .toList(growable: false);
    final chargeById = <String, Transaction>{
      for (final charge in allCharges) charge.id: charge,
    };

    // Cancelled-before-activation contracts do not convert the original charge.
    // Terminated contracts are retained as historical conversion references.
    final cardContracts = contracts.where((contract) {
      final state = contract.lifecycleState.trim().toLowerCase();
      return accountById.containsKey(contract.liabilityAccountId) &&
          state != 'cancelled' &&
          state != 'canceled';
    }).toList()
      ..sort((a, b) => a.effectiveDate.compareTo(b.effectiveDate));

    final contractById = <String, FinancingContract>{
      for (final contract in cardContracts) contract.contractId: contract,
    };
    final contractByOrigin = <String, FinancingContract>{};
    for (final contract in cardContracts) {
      contractByOrigin[contract.originReference] = contract;
    }

    final projected = <Transaction>[];
    final chargeToContract = <String, FinancingContract>{
      for (final entry in contractByOrigin.entries) entry.key: entry.value,
    };

    for (final charge in allCharges) {
      final accountId = charge.toAccountId!;
      final profile = profileByAccountId[accountId];
      final conversion = chargeToContract[charge.id];
      final closeDate = statementCloseDateForCharge(
        charge.date,
        profile?.statementDay,
      );

      // Preserve a purchase in its already-closed cycle if conversion happened
      // after that cycle closed. Otherwise the scheduled installment rows
      // replace the full principal in expense reports (ADR-069/070).
      if (conversion != null &&
          !_dateOnly(conversion.effectiveDate).isAfter(closeDate)) {
        continue;
      }

      final expenseDate = expenseDateForCharge(
        charge.date,
        profile?.statementDay,
        profile?.paymentDueDay,
      );
      if (!_inDateRange(expenseDate, startDate, endDate)) continue;

      projected.add(
        Transaction(
          id: 'cc-expense-charge:${charge.id}',
          amount: charge.amount.abs(),
          type: TransactionType.expense,
          toAccountId: accountId,
          categoryId: charge.categoryId,
          subCategoryId: charge.subCategoryId,
          date: expenseDate,
          note: charge.note,
          paymentMethod: 'credit_card',
          isExceptional: charge.isExceptional,
          currencyCode: charge.currencyCode,
          source: TransactionSource.creditCardCharge,
          createdAt: expenseDate,
          updatedAt: expenseDate,
        ),
      );
    }

    final today = _dateOnly(asOf);
    for (final installment in installments) {
      final contract = contractById[installment.contractId];
      if (contract == null) continue;

      final state = contract.lifecycleState.trim().toLowerCase();
      final status = installment.status.trim().toLowerCase();
      if (status == 'cancelled' ||
          status == 'canceled' ||
          status == 'superseded' ||
          status == 'terminated') {
        continue;
      }
      // Once a contract is terminated, retain its historical expenses but do
      // not project installments that fall after termination is known.
      if (state == 'terminated' && _dateOnly(installment.dueDate).isAfter(today)) {
        continue;
      }

      final originCharge = chargeById[contract.originReference];
      if (originCharge == null) continue;
      final expenseDate = _dateOnly(installment.dueDate);
      if (!_inDateRange(expenseDate, startDate, endDate)) continue;

      projected.add(
        Transaction(
          id: 'cc-expense-installment:${installment.installmentId}',
          amount: installment.amount.toDouble().abs(),
          type: TransactionType.expense,
          toAccountId: contract.liabilityAccountId,
          categoryId: originCharge.categoryId,
          subCategoryId: originCharge.subCategoryId,
          date: expenseDate,
          note: originCharge.note == null || originCharge.note!.trim().isEmpty
              ? 'Credit Card installment ${installment.sequence}'
              : '${originCharge.note} • Installment ${installment.sequence}',
          paymentMethod: 'credit_card',
          isExceptional: originCharge.isExceptional,
          currencyCode: originCharge.currencyCode,
          source: TransactionSource.creditCardCharge,
          createdAt: expenseDate,
          updatedAt: expenseDate,
        ),
      );
    }

    projected.sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      return byDate != 0 ? byDate : a.id.compareTo(b.id);
    });
    return projected;
  }

  /// Maps a non-financed card purchase to the month of its statement cycle.
  /// This is deliberately separate from the payment-due month: a purchase can
  /// be recognized in November's Analysis while its payment is due in December.
  /// Without complete statement settings, use next calendar month as an
  /// explicit fallback instead of silently dropping the expense.
  static DateTime expenseDateForCharge(
    DateTime chargeDate,
    int? statementDay,
    int? paymentDueDay,
  ) {
    if (statementDay == null || paymentDueDay == null) {
      return CreditCardCycleResolver.fallbackMonthFor(chargeDate);
    }
    return CreditCardCycleResolver.dueDateFor(
      statementCloseDateForCharge(chargeDate, statementDay),
      paymentDueDay,
    );
  }

  /// Closing date of the cycle to which [chargeDate] belongs. Missing cycle
  /// configuration uses that month's end only for deciding conversion history.
  static DateTime statementCloseDateForCharge(
    DateTime chargeDate,
    int? statementDay,
  ) {
    if (statementDay == null) {
      return DateTime(chargeDate.year, chargeDate.month + 1, 0);
    }
    return CreditCardCycleResolver.closeDateFor(chargeDate, statementDay);
  }

  static bool _inDateRange(DateTime value, DateTime start, DateTime end) {
    final date = _dateOnly(value);
    final first = _dateOnly(start);
    final endExclusive = DateTime(end.year, end.month, end.day + 1);
    return !date.isBefore(first) && date.isBefore(endExclusive);
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

}
