// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'allocation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AllocationAdapter extends TypeAdapter<Allocation> {
  @override
  final int typeId = 80;

  @override
  Allocation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Allocation(
      id: fields[0] as String,
      accountId: fields[1] as String,
      amount: fields[2] as double,
      type: fields[3] as AllocationType,
      referenceId: fields[4] as String,
      createdAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Allocation obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.accountId)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.referenceId)
      ..writeByte(5)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AllocationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
