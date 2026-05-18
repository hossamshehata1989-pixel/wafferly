// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reserved_money_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReservedMoneyTypeAdapter extends TypeAdapter<ReservedMoneyType> {
  @override
  final int typeId = 50;

  @override
  ReservedMoneyType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ReservedMoneyType.fixed;
      case 1:
        return ReservedMoneyType.bucket;
      case 2:
        return ReservedMoneyType.goal;
      default:
        return ReservedMoneyType.fixed;
    }
  }

  @override
  void write(BinaryWriter writer, ReservedMoneyType obj) {
    switch (obj) {
      case ReservedMoneyType.fixed:
        writer.writeByte(0);
        break;
      case ReservedMoneyType.bucket:
        writer.writeByte(1);
        break;
      case ReservedMoneyType.goal:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReservedMoneyTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
