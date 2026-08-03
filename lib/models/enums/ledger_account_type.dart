import 'package:hive/hive.dart';

part 'ledger_account_type.g.dart';

@HiveType(typeId: 30)
enum LedgerAccountType {
  @HiveField(0)
  expense,
  @HiveField(1)
  income,
  @HiveField(2)
  equity,
  @HiveField(3)
  system,
}

extension LedgerAccountTypeExtension on LedgerAccountType {
  String get string {
    switch (this) {
      case LedgerAccountType.expense:
        return 'expense';
      case LedgerAccountType.income:
        return 'income';
      case LedgerAccountType.equity:
        return 'equity';
      case LedgerAccountType.system:
        return 'system';
    }
  }

  static LedgerAccountType fromString(String value) {
    switch (value) {
      case 'expense':
        return LedgerAccountType.expense;
      case 'income':
        return LedgerAccountType.income;
      case 'equity':
        return LedgerAccountType.equity;
      case 'system':
        return LedgerAccountType.system;
      default:
        return LedgerAccountType.system;
    }
  }
}
