// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_frequency.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GoalFrequencyAdapter extends TypeAdapter<GoalFrequency> {
  @override
  final int typeId = 64;

  @override
  GoalFrequency read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return GoalFrequency.weekly;
      case 1:
        return GoalFrequency.monthly;
      default:
        return GoalFrequency.weekly;
    }
  }

  @override
  void write(BinaryWriter writer, GoalFrequency obj) {
    switch (obj) {
      case GoalFrequency.weekly:
        writer.writeByte(0);
        break;
      case GoalFrequency.monthly:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalFrequencyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
