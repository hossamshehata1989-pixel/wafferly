// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_activity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GoalActivityAdapter extends TypeAdapter<GoalActivity> {
  @override
  final int typeId = 90;

  @override
  GoalActivity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GoalActivity(
      id: fields[0] as String,
      goalId: fields[1] as String,
      type: fields[2] as String,
      amount: fields[3] as double,
      sourceAccountId: fields[4] as String?,
      destinationAccountId: fields[5] as String?,
      notes: fields[6] as String?,
      createdAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, GoalActivity obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.goalId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.sourceAccountId)
      ..writeByte(5)
      ..write(obj.destinationAccountId)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalActivityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
