// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MemberModelAdapter extends TypeAdapter<MemberModel> {
  @override
  final int typeId = 70;

  @override
  MemberModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MemberModel(
      id: fields[0] as String,
      name: fields[1] as String,
      relationshipId: fields[2] as String,
      photoUrl: fields[3] as String?,
      avatarAsset: fields[4] as String?,
      birthday: fields[5] as DateTime?,
      gender: fields[6] as String?,
      phone: fields[7] as String?,
      email: fields[8] as String?,
      accountId: fields[9] as String?,
      isLinked: fields[10] as bool,
      isOwner: fields[11] as bool,
      notes: fields[12] as String?,
      isArchived: fields[13] as bool,
      archivedAt: fields[14] as DateTime?,
      transactionsCount: fields[15] as int,
      monthlySpent: fields[16] as double,
      goalsCount: fields[17] as int,
    );
  }

  @override
  void write(BinaryWriter writer, MemberModel obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.relationshipId)
      ..writeByte(3)
      ..write(obj.photoUrl)
      ..writeByte(4)
      ..write(obj.avatarAsset)
      ..writeByte(5)
      ..write(obj.birthday)
      ..writeByte(6)
      ..write(obj.gender)
      ..writeByte(7)
      ..write(obj.phone)
      ..writeByte(8)
      ..write(obj.email)
      ..writeByte(9)
      ..write(obj.accountId)
      ..writeByte(10)
      ..write(obj.isLinked)
      ..writeByte(11)
      ..write(obj.isOwner)
      ..writeByte(12)
      ..write(obj.notes)
      ..writeByte(13)
      ..write(obj.isArchived)
      ..writeByte(14)
      ..write(obj.archivedAt)
      ..writeByte(15)
      ..write(obj.transactionsCount)
      ..writeByte(16)
      ..write(obj.monthlySpent)
      ..writeByte(17)
      ..write(obj.goalsCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemberModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
