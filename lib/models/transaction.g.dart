// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 10;

  @override
  Transaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transaction(
      id: fields[0] as String?,
      amount: fields[1] as double,
      type: fields[2] as String,
      fromAccountId: fields[3] as String?,
      toAccountId: fields[4] as String?,
      categoryId: fields[5] as String?,
      date: fields[6] as DateTime,
      note: fields[7] as String?,
      paymentMethod: fields[8] as String,
      isExceptional: fields[9] as bool,
      subCategoryId: fields[10] as String?,
      currencyCode: fields[11] as String?,
      source: fields[12] as String?,
      createdAt: fields[13] as DateTime?,
      updatedAt: fields[14] as DateTime?,
      actorMemberId: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.fromAccountId)
      ..writeByte(4)
      ..write(obj.toAccountId)
      ..writeByte(5)
      ..write(obj.categoryId)
      ..writeByte(6)
      ..write(obj.date)
      ..writeByte(7)
      ..write(obj.note)
      ..writeByte(8)
      ..write(obj.paymentMethod)
      ..writeByte(9)
      ..write(obj.isExceptional)
      ..writeByte(10)
      ..write(obj.subCategoryId)
      ..writeByte(11)
      ..write(obj.currencyCode)
      ..writeByte(12)
      ..write(obj.source)
      ..writeByte(13)
      ..write(obj.createdAt)
      ..writeByte(14)
      ..write(obj.updatedAt)
      ..writeByte(15)
      ..write(obj.actorMemberId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
