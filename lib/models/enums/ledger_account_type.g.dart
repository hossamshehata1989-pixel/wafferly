// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_account_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LedgerAccountTypeAdapter extends TypeAdapter<LedgerAccountType> {
  @override
  final int typeId = 30;

  @override
  LedgerAccountType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return LedgerAccountType.expense;
      case 1:
        return LedgerAccountType.income;
      case 2:
        return LedgerAccountType.equity;
      case 3:
        return LedgerAccountType.system;
      default:
        return LedgerAccountType.expense;
    }
  }

  @override
  void write(BinaryWriter writer, LedgerAccountType obj) {
    switch (obj) {
      case LedgerAccountType.expense:
        writer.writeByte(0);
        break;
      case LedgerAccountType.income:
        writer.writeByte(1);
        break;
      case LedgerAccountType.equity:
        writer.writeByte(2);
        break;
      case LedgerAccountType.system:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LedgerAccountTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
