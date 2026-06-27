// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_rule.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScheduleRuleAdapter extends TypeAdapter<ScheduleRule> {
  @override
  final int typeId = 95;

  @override
  ScheduleRule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScheduleRule(
      id: fields[0] as String,
      frequency: fields[1] as Frequency,
      startDate: fields[2] as DateTime,
      nextDueDate: fields[3] as DateTime,
      endDate: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ScheduleRule obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.frequency)
      ..writeByte(2)
      ..write(obj.startDate)
      ..writeByte(3)
      ..write(obj.nextDueDate)
      ..writeByte(4)
      ..write(obj.endDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleRuleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
