// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commitment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CommitmentAdapter extends TypeAdapter<Commitment> {
  @override
  final int typeId = 96;

  @override
  Commitment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Commitment(
      id: fields[0] as String,
      title: fields[1] as String,
      type: fields[2] as CommitmentType,
      status: fields[3] as CommitmentStatus,
      amount: fields[4] as double,
      amountMode: fields[5] as CommitmentAmountMode,
      scheduleRuleId: fields[8] as String,
      sourceAccountId: fields[6] as String?,
      destinationAccountId: fields[7] as String?,
      liabilityAccountId: fields[9] as String?,
      notes: fields[10] as String?,
      isArchived: fields[11] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Commitment obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.amountMode)
      ..writeByte(6)
      ..write(obj.sourceAccountId)
      ..writeByte(7)
      ..write(obj.destinationAccountId)
      ..writeByte(8)
      ..write(obj.scheduleRuleId)
      ..writeByte(9)
      ..write(obj.liabilityAccountId)
      ..writeByte(10)
      ..write(obj.notes)
      ..writeByte(11)
      ..write(obj.isArchived);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommitmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
