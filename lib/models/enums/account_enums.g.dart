// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_enums.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AccountNatureAdapter extends TypeAdapter<AccountNature> {
  @override
  final int typeId = 2;

  @override
  AccountNature read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AccountNature.asset;
      case 1:
        return AccountNature.liability;
      default:
        return AccountNature.asset;
    }
  }

  @override
  void write(BinaryWriter writer, AccountNature obj) {
    switch (obj) {
      case AccountNature.asset:
        writer.writeByte(0);
        break;
      case AccountNature.liability:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountNatureAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AccountGroupAdapter extends TypeAdapter<AccountGroup> {
  @override
  final int typeId = 3;

  @override
  AccountGroup read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AccountGroup.liquidity;
      case 1:
        return AccountGroup.investments;
      case 2:
        return AccountGroup.liabilities;
      case 3:
        return AccountGroup.receivable;
      case 4:
        return AccountGroup.savings;
      default:
        return AccountGroup.liquidity;
    }
  }

  @override
  void write(BinaryWriter writer, AccountGroup obj) {
    switch (obj) {
      case AccountGroup.liquidity:
        writer.writeByte(0);
        break;
      case AccountGroup.investments:
        writer.writeByte(1);
        break;
      case AccountGroup.liabilities:
        writer.writeByte(2);
        break;
      case AccountGroup.receivable:
        writer.writeByte(3);
        break;
      case AccountGroup.savings:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountGroupAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
