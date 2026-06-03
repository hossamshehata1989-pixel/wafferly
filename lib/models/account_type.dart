// lib/models/enums/account_type.dart
import 'package:hive/hive.dart';

part 'account_type.g.dart';

@HiveType(typeId: 4)
enum AccountType {
  @HiveField(0)
  cash,
  @HiveField(1)
  bank,
  @HiveField(2)
  wallet,
  @HiveField(3)
  debitCard,
  @HiveField(4)
  debt,
  @HiveField(5)
  loan,
  @HiveField(6)
  creditCard,
  @HiveField(7)
  installment,
  @HiveField(8)
  investment,
  @HiveField(9)
  gold,
  @HiveField(10)
  stocks,
  @HiveField(11)
  certificates,
  @HiveField(12)
  lent,
  @HiveField(13)
  rosca,
  @HiveField(14)
  realSaving,

  @HiveField(15)
  savingCircle,
}

extension AccountTypeExtension on AccountType {
  String get string {
    switch (this) {
      case AccountType.cash:
        return 'cash';
      case AccountType.bank:
        return 'bank';
      case AccountType.wallet:
        return 'wallet';
      case AccountType.debitCard:
        return 'debitCard';
      case AccountType.debt:
        return 'debt';
      case AccountType.loan:
        return 'loan';
      case AccountType.creditCard:
        return 'creditCard';
      case AccountType.installment:
        return 'installment';
      case AccountType.investment:
        return 'investment';
      case AccountType.gold:
        return 'gold';
      case AccountType.stocks:
        return 'stocks';
      case AccountType.certificates:
        return 'certificates';
      case AccountType.lent:
        return 'lent';
      case AccountType.rosca:
        return 'rosca';
      case AccountType.realSaving:
        return 'realSaving';
      case AccountType.savingCircle:
        return 'savingCircle';
    }
  }

  static AccountType fromString(String value) {
    switch (value) {
      case 'cash':
        return AccountType.cash;
      case 'bank':
        return AccountType.bank;
      case 'wallet':
        return AccountType.wallet;
      case 'debitCard':
        return AccountType.debitCard;
      case 'debt':
        return AccountType.debt;
      case 'loan':
        return AccountType.loan;
      case 'creditCard':
        return AccountType.creditCard;
      case 'installment':
        return AccountType.installment;
      case 'investment':
        return AccountType.investment;
      case 'gold':
        return AccountType.gold;
      case 'stocks':
        return AccountType.stocks;
      case 'certificates':
        return AccountType.certificates;
      case 'lent':
        return AccountType.lent;
      case 'rosca':
        return AccountType.rosca;
      case 'realSaving':
        return AccountType.realSaving;
      case 'savingCircle':
        return AccountType.savingCircle;
      default:
        return AccountType.cash;
    }
  }
}
