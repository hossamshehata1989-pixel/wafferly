// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_occurrence.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScheduleOccurrenceAdapter extends TypeAdapter<ScheduleOccurrence> {
  @override
  final int typeId = 98;

  @override
  ScheduleOccurrence read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScheduleOccurrence(
      id: fields[0] as String,
      scheduleRuleId: fields[1] as String,
      dueDate: fields[2] as DateTime,
      status: fields[3] as ScheduleOccurrenceStatus,
    );
  }

  @override
  void write(BinaryWriter writer, ScheduleOccurrence obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.scheduleRuleId)
      ..writeByte(2)
      ..write(obj.dueDate)
      ..writeByte(3)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleOccurrenceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
