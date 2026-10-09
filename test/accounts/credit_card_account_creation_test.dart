import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:wafferly/application/credit_card/credit_card_account_application_service.dart';
import 'package:wafferly/credit_card/domain/credit_card_profile.dart';
import 'package:wafferly/models/account.dart';
import 'package:wafferly/models/enums/account_enums.dart';
import 'package:wafferly/services/account_service.dart';

void main() {
  late Directory tempDirectory;
  late Box<Account> accountsBox;
  late Box<CreditCardProfile> profileBox;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('wafferly_cc_account_');
    Hive.init(tempDirectory.path);

    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(AccountAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(AccountNatureAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(AccountGroupAdapter());
    }
    if (!Hive.isAdapterRegistered(100)) {
      Hive.registerAdapter(CreditCardProfileAdapter());
    }

    accountsBox = await Hive.openBox<Account>('accounts');
    profileBox = await Hive.openBox<CreditCardProfile>('credit_card_profiles');
  });

  tearDown(() async {
    await accountsBox.close();
    await profileBox.close();
    await Hive.close();
    await tempDirectory.delete(recursive: true);
  });

  test('creating a credit card requires an existing bank account, not a payment link', () async {
    final accountService = AccountService();
    // A newly registered bank account has no transactions and no credited balance.
    await accountService.createAccount(
      name: 'Main Bank Account',
      type: 'bank',
      currency: 'EGP',
    );
    final cardService = CreditCardAccountApplicationService(
      accountService: accountService,
      profileBox: profileBox,
    );

    final account = await cardService.create(
      name: 'CIB Credit Card',
      bank: 'CIB',
      currency: 'EGP',
      creditLimitValue: '30000',
      last4Digits: '5678',
      cardKind: 'virtual',
      cardNetwork: 'Visa',
      statementDay: 5,
      paymentDueDay: 30,
    );

    expect(account.type, 'creditCard');
    expect(account.group, AccountGroup.liabilities);
    expect(account.nature, AccountNature.liability);
    expect(account.provider, 'CIB');
    expect(account.accountNumber, '5678');

    final profiles = profileBox.values
        .where((profile) => profile.accountId == account.id)
        .toList();
    expect(profiles, hasLength(1));
    expect(profiles.single.creditLimit.toString(), '30000');
    expect(profiles.single.cardKind, 'virtual');
    expect(profiles.single.cardNetwork, 'Visa');
    expect(profiles.single.statementDay, 5);
    expect(profiles.single.paymentDueDay, 30);
    expect(profiles.single.linkedDebitCardAccountId, isNull);
  });

  test('creating a credit card is rejected when no bank account exists', () async {
    final accountService = AccountService();
    // A cash wallet or debit card alone does not satisfy the bank-account rule.
    await accountService.createAccount(
      name: 'Cash Wallet',
      type: 'cash',
      currency: 'EGP',
    );
    final cardService = CreditCardAccountApplicationService(
      accountService: accountService,
      profileBox: profileBox,
    );

    await expectLater(
      cardService.create(
        name: 'Credit Card Without Bank Account',
        bank: 'CIB',
        currency: 'EGP',
        creditLimitValue: '1000',
      ),
      throwsA(isA<StateError>()),
    );
    expect(
      accountsBox.values.where((item) => item.type == 'creditCard'),
      isEmpty,
    );
  });
}
