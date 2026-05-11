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
  @HiveField(0)
  moneyYouHave,
  @HiveField(1)
  investments,
  @HiveField(2)
  moneyYouOwe,
  @HiveField(3)
  moneyYouWillGet,
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
      case AccountGroup.moneyYouHave:
        return 'moneyYouHave';
      case AccountGroup.investments:
        return 'investments';
      case AccountGroup.moneyYouOwe:
        return 'moneyYouOwe';
      case AccountGroup.moneyYouWillGet:
        return 'moneyYouWillGet';
    }
  }

  static AccountGroup fromString(String value) {
    switch (value) {
      case 'moneyYouHave':
        return AccountGroup.moneyYouHave;
      case 'investments':
        return AccountGroup.investments;
      case 'moneyYouOwe':
        return AccountGroup.moneyYouOwe;
      case 'moneyYouWillGet':
        return AccountGroup.moneyYouWillGet;
      default:
        return AccountGroup.moneyYouHave;
    }
  }
}