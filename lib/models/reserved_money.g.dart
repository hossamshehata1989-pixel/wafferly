// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reserved_money.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReservedMoneyAdapter extends TypeAdapter<ReservedMoney> {
  @override
  final int typeId = 51;

  @override
  ReservedMoney read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReservedMoney(
      id: fields[0] as String,
      accountId: fields[1] as String,
      title: fields[2] as String,
      amount: fields[3] as double,
      type: fields[4] as ReservedMoneyType,
      createdAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ReservedMoney obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.accountId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReservedMoneyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
