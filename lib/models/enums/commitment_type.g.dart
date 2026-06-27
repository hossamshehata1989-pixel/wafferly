// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commitment_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CommitmentTypeAdapter extends TypeAdapter<CommitmentType> {
  @override
  final int typeId = 91;

  @override
  CommitmentType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CommitmentType.income;
      case 1:
        return CommitmentType.expense;
      case 2:
        return CommitmentType.transfer;
      case 3:
        return CommitmentType.liabilityPayment;
      default:
        return CommitmentType.income;
    }
  }

  @override
  void write(BinaryWriter writer, CommitmentType obj) {
    switch (obj) {
      case CommitmentType.income:
        writer.writeByte(0);
        break;
      case CommitmentType.expense:
        writer.writeByte(1);
        break;
      case CommitmentType.transfer:
        writer.writeByte(2);
        break;
      case CommitmentType.liabilityPayment:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommitmentTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
