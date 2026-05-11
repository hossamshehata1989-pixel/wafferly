// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_purpose.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LedgerPurposeAdapter extends TypeAdapter<LedgerPurpose> {
  @override
  final int typeId = 21;

  @override
  LedgerPurpose read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return LedgerPurpose.expense;
      case 1:
        return LedgerPurpose.income;
      case 2:
        return LedgerPurpose.transfer;
      case 3:
        return LedgerPurpose.debt;
      case 4:
        return LedgerPurpose.adjustment;
      case 5:
        return LedgerPurpose.investment;
      default:
        return LedgerPurpose.expense;
    }
  }

  @override
  void write(BinaryWriter writer, LedgerPurpose obj) {
    switch (obj) {
      case LedgerPurpose.expense:
        writer.writeByte(0);
        break;
      case LedgerPurpose.income:
        writer.writeByte(1);
        break;
      case LedgerPurpose.transfer:
        writer.writeByte(2);
        break;
      case LedgerPurpose.debt:
        writer.writeByte(3);
        break;
      case LedgerPurpose.adjustment:
        writer.writeByte(4);
        break;
      case LedgerPurpose.investment:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LedgerPurposeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
