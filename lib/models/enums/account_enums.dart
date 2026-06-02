import 'package:hive/hive.dart';

part 'account_enums.g.dart';

@HiveType(typeId: 2)
enum AccountNature {
  @HiveField(0)
  asset,

  @HiveField(1)
  liability,
}

@HiveType(typeId: 3)
enum AccountGroup {
  // كان moneyYouHave
  @HiveField(0)
  liquidity,

  // كان investments
  @HiveField(1)
  investments,

  // كان moneyYouOwe
  @HiveField(2)
  liabilities,

  // كان moneyYouWillGet
  @HiveField(3)
  receivable,

  // جديد
  @HiveField(4)
  savings,
}

extension AccountNatureExtension on AccountNature {
  String get string {
    switch (this) {
      case AccountNature.asset:
        return 'asset';

      case AccountNature.liability:
        return 'liability';
    }
  }

  static AccountNature fromString(String value) {
    switch (value) {
      case 'asset':
        return AccountNature.asset;

      case 'liability':
        return AccountNature.liability;

      default:
        return AccountNature.asset;
    }
  }
}

extension AccountGroupExtension on AccountGroup {
  String get string {
    switch (this) {
      case AccountGroup.liquidity:
        return 'liquidity';

      case AccountGroup.savings:
        return 'savings';

      case AccountGroup.investments:
        return 'investments';

      case AccountGroup.liabilities:
        return 'liabilities';

      case AccountGroup.receivable:
        return 'receivable';
    }
  }

  static AccountGroup fromString(String value) {
    switch (value) {
      case 'liquidity':
        return AccountGroup.liquidity;

      case 'savings':
        return AccountGroup.savings;

      case 'investments':
        return AccountGroup.investments;

      case 'liabilities':
        return AccountGroup.liabilities;

      case 'receivable':
        return AccountGroup.receivable;

      // Migration Support
      case 'moneyYouHave':
        return AccountGroup.liquidity;

      case 'moneyYouOwe':
        return AccountGroup.liabilities;

      case 'moneyYouWillGet':
        return AccountGroup.receivable;

      default:
        return AccountGroup.liquidity;
    }
  }
}
