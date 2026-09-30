import 'package:hive_flutter/hive_flutter.dart';

import 'package:uuid/uuid.dart';

import '../../core/money/money.dart';

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

  List<Account> getActiveDebitCardAccounts() => _accountService
      .getAllActiveAccounts()
      .where((account) => account.type == 'debitCard' && account.group == AccountGroup.liquidity)
      .toList();

  Future<Account> create({
    required String name,
    required String bank,
    required String currency,
    required String creditLimitValue,
    String? last4Digits,
    String cardKind = 'physical',
    String? notes,
    String? cardNetwork,
    int? statementDay,
    int? paymentDueDay,
    String? linkedDebitCardAccountId,
    String? annualFeeValue,
  }) async {
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
        statementDay: statementDay,
        paymentDueDay: paymentDueDay,
        linkedDebitCardAccountId: linkedDebitCardAccountId,
        annualFee: annualFee,
      );
      await _profileBox.put(profile.id, profile);
      return account;
    } catch (_) {
      await _accountService.archiveAccount(account.id);
      rethrow;
    }
  }
}

