// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'allocation_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AllocationTypeAdapter extends TypeAdapter<AllocationType> {
  @override
  final int typeId = 81;

  @override
  AllocationType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AllocationType.goal;
      case 1:
        return AllocationType.saving;
      case 2:
        return AllocationType.budgetSurplus;
      default:
        return AllocationType.goal;
    }
  }

  @override
  void write(BinaryWriter writer, AllocationType obj) {
    switch (obj) {
      case AllocationType.goal:
        writer.writeByte(0);
        break;
      case AllocationType.saving:
        writer.writeByte(1);
        break;
      case AllocationType.budgetSurplus:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AllocationTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
