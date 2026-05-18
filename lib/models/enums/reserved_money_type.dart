// lib/models/enums/reserved_money_type.dart

import 'package:hive/hive.dart';

part 'reserved_money_type.g.dart';

@HiveType(typeId: 50) // ✅ متطابق مع main.dart
enum ReservedMoneyType {
  @HiveField(0)
  fixed,
  @HiveField(1)
  bucket,
  @HiveField(2)
  goal,
}

extension ReservedMoneyTypeExtension on ReservedMoneyType {
  String get string {
    switch (this) {
      case ReservedMoneyType.fixed:
        return 'fixed';
      case ReservedMoneyType.bucket:
        return 'bucket';
      case ReservedMoneyType.goal:
        return 'goal';
    }
  }

  static ReservedMoneyType fromString(String value) {
    switch (value) {
      case 'fixed':
        return ReservedMoneyType.fixed;
      case 'bucket':
        return ReservedMoneyType.bucket;
      case 'goal':
        return ReservedMoneyType.goal;
      default:
        return ReservedMoneyType.fixed;
    }
  }
}
