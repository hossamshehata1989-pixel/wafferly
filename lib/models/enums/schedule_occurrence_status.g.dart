// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_occurrence_status.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScheduleOccurrenceStatusAdapter
    extends TypeAdapter<ScheduleOccurrenceStatus> {
  @override
  final int typeId = 99;

  @override
  ScheduleOccurrenceStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ScheduleOccurrenceStatus.pending;
      case 1:
        return ScheduleOccurrenceStatus.skipped;
      case 2:
        return ScheduleOccurrenceStatus.completed;
      default:
        return ScheduleOccurrenceStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, ScheduleOccurrenceStatus obj) {
    switch (obj) {
      case ScheduleOccurrenceStatus.pending:
        writer.writeByte(0);
        break;
      case ScheduleOccurrenceStatus.skipped:
        writer.writeByte(1);
        break;
      case ScheduleOccurrenceStatus.completed:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleOccurrenceStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
