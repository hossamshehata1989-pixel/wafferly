// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_account.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LedgerAccountAdapter extends TypeAdapter<LedgerAccount> {
  @override
  final int typeId = 31;

  @override
  LedgerAccount read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LedgerAccount(
      id: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as LedgerAccountType,
      categoryId: fields[3] as String?,
      isSystem: fields[4] as bool,
      parentId: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LedgerAccount obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.categoryId)
      ..writeByte(4)
      ..write(obj.isSystem)
      ..writeByte(5)
      ..write(obj.parentId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LedgerAccountAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
