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

    // Nature migration
    AccountNature nature;

    if (fields[13] is AccountNature) {
      nature = fields[13] as AccountNature;
    } else if (fields[4] is String) {
      nature = AccountNatureExtension.fromString(fields[4] as String);
    } else {
      nature = AccountNature.asset;
    }

    // Group migration
    AccountGroup group;

    final groupValue = fields[14];

    if (groupValue is AccountGroup) {
      group = groupValue;
    } else if (groupValue is int &&
        groupValue >= 0 &&
        groupValue < AccountGroup.values.length) {
      group = AccountGroup.values[groupValue];
    } else {
      group = AccountGroup.moneyYouHave;
    }

    return Account(
      id: fields[0] as String,
      bookId: fields[1] as String,
      memberId: fields[12] as String,
      name: fields[2] as String,
      type: fields[3] as String,
      currency: fields[5] as String,
      createdAt: fields[11] as DateTime,

      group: group,
      nature: nature,

      isArchived: fields[15] as bool? ?? false,

      provider: fields[6] as String?,
      accountNumber: fields[7] as String?,
      color: fields[8] as String?,
      icon: fields[9] as String?,
      notes: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Account obj) {
    writer.writeByte(15);

    writer.writeByte(0);
    writer.write(obj.id);

    writer.writeByte(1);
    writer.write(obj.bookId);

    writer.writeByte(2);
    writer.write(obj.name);

    writer.writeByte(3);
    writer.write(obj.type);

    writer.writeByte(5);
    writer.write(obj.currency);

    writer.writeByte(6);
    writer.write(obj.provider);

    writer.writeByte(7);
    writer.write(obj.accountNumber);

    writer.writeByte(8);
    writer.write(obj.color);

    writer.writeByte(9);
    writer.write(obj.icon);

    writer.writeByte(10);
    writer.write(obj.notes);

    writer.writeByte(11);
    writer.write(obj.createdAt);

    writer.writeByte(12);
    writer.write(obj.memberId);

    writer.writeByte(13);
    writer.write(obj.nature);

    // اكتب enum نفسه
    writer.writeByte(14);
    writer.write(obj.group);

    writer.writeByte(15);
    writer.write(obj.isArchived);
  }
}
