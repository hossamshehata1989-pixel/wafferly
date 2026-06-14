// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_funding_method.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GoalFundingMethodAdapter extends TypeAdapter<GoalFundingMethod> {
  @override
  final int typeId = 63;

  @override
  GoalFundingMethod read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return GoalFundingMethod.saving;
      case 1:
        return GoalFundingMethod.reserve;
      default:
        return GoalFundingMethod.saving;
    }
  }

  @override
  void write(BinaryWriter writer, GoalFundingMethod obj) {
    switch (obj) {
      case GoalFundingMethod.saving:
        writer.writeByte(0);
        break;
      case GoalFundingMethod.reserve:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalFundingMethodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
