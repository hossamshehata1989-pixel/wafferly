// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GoalAdapter extends TypeAdapter<Goal> {
  @override
  final int typeId = 60;

  @override
  Goal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Goal(
      id: fields[0] as String,
      title: fields[1] as String,
      targetAmount: fields[2] as double,
      type: fields[6] as GoalType,
      targetDate: fields[3] as DateTime?,
      reserveMoney: fields[4] as bool,
      status: fields[5] as GoalStatus,
      notes: fields[7] as String?,
      recurringRule: fields[8] as String?,
      contributionAmount: fields[9] as double?,
      nextDueDate: fields[10] as DateTime?,
      preferredSourceAccountId: fields[11] as String?,
      preferredSavingAccountId: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Goal obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.targetAmount)
      ..writeByte(3)
      ..write(obj.targetDate)
      ..writeByte(4)
      ..write(obj.reserveMoney)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.type)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.recurringRule)
      ..writeByte(9)
      ..write(obj.contributionAmount)
      ..writeByte(10)
      ..write(obj.nextDueDate)
      ..writeByte(11)
      ..write(obj.preferredSourceAccountId)
      ..writeByte(12)
      ..write(obj.preferredSavingAccountId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
