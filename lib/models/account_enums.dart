import 'package:hive/hive.dart';

part 'account_enums.g.dart';

/// 🟢 Account Nature (Asset / Liability)
/// ❗ typeId = 2 (علشان 1 محجوز لـ Account)
@HiveType(typeId: 2)
enum AccountNature {
  @HiveField(0)
  asset,

  @HiveField(1)
  liability,
}

/// 🟢 Account Group (التقسيم اللي بيظهر في UI)
/// ❗ typeId = 3
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