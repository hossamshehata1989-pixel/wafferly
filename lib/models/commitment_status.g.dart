// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commitment_status.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CommitmentStatusAdapter extends TypeAdapter<CommitmentStatus> {
  @override
  final int typeId = 92;

  @override
  CommitmentStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CommitmentStatus.active;
      case 1:
        return CommitmentStatus.paused;
      case 2:
        return CommitmentStatus.completed;
      case 3:
        return CommitmentStatus.cancelled;
      default:
        return CommitmentStatus.active;
    }
  }

  @override
  void write(BinaryWriter writer, CommitmentStatus obj) {
    switch (obj) {
      case CommitmentStatus.active:
        writer.writeByte(0);
        break;
      case CommitmentStatus.paused:
        writer.writeByte(1);
        break;
      case CommitmentStatus.completed:
        writer.writeByte(2);
        break;
      case CommitmentStatus.cancelled:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommitmentStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
