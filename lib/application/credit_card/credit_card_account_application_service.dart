import 'package:hive_flutter/hive_flutter.dart';

import 'package:uuid/uuid.dart';

import '../../core/money/money.dart';
import 'credit_card_due_date_policy.dart';

import '../../credit_card/domain/credit_card_profile.dart';
import '../../models/account.dart';
import '../../models/enums/account_enums.dart';
import '../../services/account_service.dart';

/// Creates the Account + CreditCardProfile pair required by a Credit Card
/// account. This does not create an opening financial transaction: a newly
/// created credit card starts with zero outstanding exposure.
final class CreditCardAccountApplicationService {
  CreditCardAccountApplicationService({
    AccountService? accountService,
    Box<CreditCardProfile>? profileBox,
  })  : _accountService = accountService ?? AccountService(),
        _profileBox =
            profileBox ?? Hive.box<CreditCardProfile>('credit_card_profiles');

  final AccountService _accountService;
  final Box<CreditCardProfile> _profileBox;
  static const _uuid = Uuid();

  /// Active bank accounts eligible to be linked to a new credit card.
  /// Account balance is intentionally ignored.
  List<Account> getActiveBankAccounts() => _accountService
      .getAllActiveAccounts()
      .where(
        (account) =>
            account.bookId == 'default' &&
            !account.isArchived &&
            account.group == AccountGroup.liquidity &&
            account.type == 'bank',
      )
      .toList();

  bool hasActiveBankAccount() => getActiveBankAccounts().isNotEmpty;

  Future<Account> create({
    required String name,
    required String bank,
    required String currency,
    required String creditLimitValue,
    required String linkedBankAccountId,
    String? last4Digits,
    String cardKind = 'physical',
    String? notes,
    String? cardNetwork,
    int? statementDay,
    int? paymentDueDay,
    int? statementStartDay,
    List<int>? paymentReminderDays,
    List<int>? graceDays,
    String? annualFeeValue,
    String cardVisual = 'credit_midnight',
    String dueDateCalculationMethod = CreditCardDueDatePolicy.fixedCalendarDay,
    int? dueDaysAfterStatement,
    String weekendHolidayPolicy = CreditCardDueDatePolicy.noAdjustment,
  }) async {
    final activeBankAccounts = getActiveBankAccounts();
    Account? linkedBankAccount;
    for (final candidate in activeBankAccounts) {
      if (candidate.id == linkedBankAccountId) {
        linkedBankAccount = candidate;
        break;
      }
    }
    if (linkedBankAccount == null) {
      throw StateError(
        'Select an active bank account to link to the credit card.',
      );
    }
    if (linkedBankAccount.currency != currency) {
      throw StateError(
        'Credit card currency must match the linked bank account currency.',
      );
    }

    final normalizedLimit = creditLimitValue.trim();
    final creditLimit = Money.parse(normalizedLimit);

    Money? annualFee;
    if (annualFeeValue != null && annualFeeValue.trim().isNotEmpty) {
      annualFee = Money.parse(annualFeeValue.trim());
      if (annualFee < Money.zero) {
        throw ArgumentError('Annual fee cannot be negative.');
      }
    }
    if (creditLimit <= Money.zero) {
      throw ArgumentError('Credit limit must be greater than zero.');
    }

    if (dueDateCalculationMethod == CreditCardDueDatePolicy.fixedOffsetDays) {
      if (dueDaysAfterStatement == null ||
          dueDaysAfterStatement < 1 ||
          dueDaysAfterStatement > 90) {
        throw ArgumentError('Due date offset must be between 1 and 90 days.');
      }
    } else if (paymentDueDay == null || paymentDueDay < 1 || paymentDueDay > 31) {
      throw ArgumentError('Payment due day must be between 1 and 31.');
    }

    final effectiveStatementDay = statementDay ??
        (statementStartDay == null
            ? null
            : (statementStartDay == 1 ? 31 : statementStartDay - 1));
    if (effectiveStatementDay == null ||
        effectiveStatementDay < 1 ||
        effectiveStatementDay > 31) {
      throw ArgumentError('Statement closing day must be between 1 and 31.');
    }

    final account = await _accountService.createAccount(
      name: name.trim(),
      type: 'creditCard',
      currency: currency,
      provider: bank.trim().isEmpty ? null : bank.trim(),
      accountNumber: last4Digits?.trim().isEmpty == true
          ? null
          : last4Digits?.trim(),
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
    );

    try {
      final profile = CreditCardProfile.fromMoney(
        id: _uuid.v4(),
        accountId: account.id,
        creditLimit: creditLimit,
        cardKind: cardKind,
        cardNetwork: cardNetwork,
        // statementDay is the actual statement closing day; legacy callers may
        // still pass statementStartDay and receive the old conversion below.
        statementDay: effectiveStatementDay,
        paymentDueDay: dueDateCalculationMethod == CreditCardDueDatePolicy.fixedCalendarDay
            ? paymentDueDay
            : null,
        statementStartDay: statementStartDay,
        paymentReminderDays: paymentReminderDays,
        graceDays: graceDays,
        annualFee: annualFee,
        cardVisual: cardVisual,
        linkedBankAccountId: linkedBankAccount.id,
        dueDateCalculationMethod: dueDateCalculationMethod,
        dueDaysAfterStatement: dueDateCalculationMethod == CreditCardDueDatePolicy.fixedOffsetDays
            ? dueDaysAfterStatement
            : null,
        weekendHolidayPolicy: weekendHolidayPolicy,
      );
      await _profileBox.put(profile.id, profile);
      return account;
    } catch (_) {
      await _accountService.archiveAccount(account.id);
      rethrow;
    }
  }
}

