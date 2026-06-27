// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commitment_amount_mode.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CommitmentAmountModeAdapter extends TypeAdapter<CommitmentAmountMode> {
  @override
  final int typeId = 93;

  @override
  CommitmentAmountMode read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CommitmentAmountMode.fixed;
      case 1:
        return CommitmentAmountMode.variable;
      default:
        return CommitmentAmountMode.fixed;
    }
  }

  @override
  void write(BinaryWriter writer, CommitmentAmountMode obj) {
    switch (obj) {
      case CommitmentAmountMode.fixed:
        writer.writeByte(0);
        break;
      case CommitmentAmountMode.variable:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommitmentAmountModeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
