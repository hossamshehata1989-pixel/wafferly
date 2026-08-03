import 'package:hive/hive.dart';

part 'entry_type.g.dart';

@HiveType(typeId: 20) // ID جديد غير مستخدم
enum EntryType {
  @HiveField(0)
  debit,
  @HiveField(1)
  credit,
}

extension EntryTypeExtension on EntryType {
  String get string {
    switch (this) {
      case EntryType.debit:
        return 'debit';
      case EntryType.credit:
        return 'credit';
    }
  }

  static EntryType fromString(String value) {
    switch (value) {
      case 'debit':
        return EntryType.debit;
      case 'credit':
        return EntryType.credit;
      default:
        return EntryType.debit;
    }
  }
}
