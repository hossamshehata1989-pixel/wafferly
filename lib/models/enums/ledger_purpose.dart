import 'package:hive/hive.dart';

part 'ledger_purpose.g.dart';

@HiveType(typeId: 21) // ID جديد غير مستخدم
enum LedgerPurpose {
  @HiveField(0)
  expense,
  @HiveField(1)
  income,
  @HiveField(2)
  transfer,
  @HiveField(3)
  debt,
  @HiveField(4)
  adjustment,
  @HiveField(5)
  investment,
}

extension LedgerPurposeExtension on LedgerPurpose {
  String get string {
    switch (this) {
      case LedgerPurpose.expense:
        return 'expense';
      case LedgerPurpose.income:
        return 'income';
      case LedgerPurpose.transfer:
        return 'transfer';
      case LedgerPurpose.debt:
        return 'debt';
      case LedgerPurpose.adjustment:
        return 'adjustment';
      case LedgerPurpose.investment:
        return 'investment';
    }
  }

  static LedgerPurpose fromString(String value) {
    switch (value) {
      case 'expense':
        return LedgerPurpose.expense;
      case 'income':
        return LedgerPurpose.income;
      case 'transfer':
        return LedgerPurpose.transfer;
      case 'debt':
        return LedgerPurpose.debt;
      case 'adjustment':
        return LedgerPurpose.adjustment;
      case 'investment':
        return LedgerPurpose.investment;
      default:
        return LedgerPurpose.expense;
    }
  }
}
