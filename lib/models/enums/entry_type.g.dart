// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entry_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EntryTypeAdapter extends TypeAdapter<EntryType> {
  @override
  final int typeId = 20;

  @override
  EntryType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return EntryType.debit;
      case 1:
        return EntryType.credit;
      default:
        return EntryType.debit;
    }
  }

  @override
  void write(BinaryWriter writer, EntryType obj) {
    switch (obj) {
      case EntryType.debit:
        writer.writeByte(0);
        break;
      case EntryType.credit:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntryTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
