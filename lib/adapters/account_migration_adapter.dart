// lib/adapters/account_migration_adapter.dart

// TEMPORARY MIGRATION ADAPTER
// This adapter handles legacy data (field 4: String nature, field 13: AccountNature natureEnum)
// and writes only field 13 (AccountNature nature).
// After full migration, can be replaced with auto-generated AccountAdapter.

import 'package:hive/hive.dart';
import '../models/account.dart';
import '../models/enums/account_enums.dart';

class AccountMigrationAdapter extends TypeAdapter<Account> {
  @override
  final int typeId = 1;

  @override
  Account read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final fieldId = reader.readByte();
      fields[fieldId] = reader.read();
    }

    final id = fields[0] as String;
    final bookId = fields[1] as String;
    final name = fields[2] as String;
    final type = fields[3] as String;
    final currency = fields[5] as String;
    final createdAt = fields[11] as DateTime;
    final memberId = fields[12] as String;
    final group = fields[14] as AccountGroup;
    final isArchived = fields[15] as bool? ?? false;

    // تحويل الـ nature من البيانات القديمة
    AccountNature nature;
    if (fields[13] is AccountNature) {
      nature = fields[13] as AccountNature;
    } else if (fields[4] is String) {
      final legacyNatureString = fields[4] as String;
      nature = AccountNatureExtension.fromString(legacyNatureString);
    } else {
      nature = AccountNature.asset;
    }

    return Account(
      id: id,
      bookId: bookId,
      memberId: memberId,
      name: name,
      type: type,
      currency: currency,
      createdAt: createdAt,
      group: group,
      isArchived: isArchived,
      nature: nature,
      provider: fields[6] as String?,
      accountNumber: fields[7] as String?,
      color: fields[8] as String?,
      icon: fields[9] as String?,
      notes: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Account obj) {
    // ✅ عدد الحقول الفعلية المكتوبة = 15
    writer.writeByte(15);
    
    writer.writeByte(0); writer.write(obj.id);
    writer.writeByte(1); writer.write(obj.bookId);
    writer.writeByte(2); writer.write(obj.name);
    writer.writeByte(3); writer.write(obj.type);
    // Skipping field 4 (old String nature) – not written
    writer.writeByte(5); writer.write(obj.currency);
    writer.writeByte(6); writer.write(obj.provider);
    writer.writeByte(7); writer.write(obj.accountNumber);
    writer.writeByte(8); writer.write(obj.color);
    writer.writeByte(9); writer.write(obj.icon);
    writer.writeByte(10); writer.write(obj.notes);
    writer.writeByte(11); writer.write(obj.createdAt);
    writer.writeByte(12); writer.write(obj.memberId);
    writer.writeByte(13); writer.write(obj.nature); // الحقل الجديد بنفس الرقم
    writer.writeByte(14); writer.write(obj.group);
    writer.writeByte(15); writer.write(obj.isArchived);
  }
}