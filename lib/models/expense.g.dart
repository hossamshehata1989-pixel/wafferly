// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExpenseAdapter extends TypeAdapter<Expense> {
  @override
  final int typeId = 0;

  @override
  Expense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Expense(
      id: fields[0] as String?,
      amount: fields[1] as double,
      mainCategoryId: fields[2] as String,
      subCategoryId: fields[4] as String?,
      date: fields[6] as DateTime,
      isExceptional: fields[7] as bool,
      note: fields[8] as String?,
      paymentMethod: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Expense obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.mainCategoryId)
      ..writeByte(4)
      ..write(obj.subCategoryId)
      ..writeByte(6)
      ..write(obj.date)
      ..writeByte(7)
      ..write(obj.isExceptional)
      ..writeByte(8)
      ..write(obj.note)
      ..writeByte(9)
      ..write(obj.paymentMethod);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
