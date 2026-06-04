// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AccountTypeAdapter extends TypeAdapter<AccountType> {
  @override
  final int typeId = 4;

  @override
  AccountType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AccountType.cash;
      case 1:
        return AccountType.bank;
      case 2:
        return AccountType.wallet;
      case 3:
        return AccountType.debitCard;
      case 4:
        return AccountType.debt;
      case 5:
        return AccountType.loan;
      case 6:
        return AccountType.creditCard;
      case 7:
        return AccountType.installment;
      case 8:
        return AccountType.investment;
      case 9:
        return AccountType.gold;
      case 10:
        return AccountType.stocks;
      case 11:
        return AccountType.certificates;
      case 12:
        return AccountType.lent;
      case 13:
        return AccountType.rosca;
      case 14:
        return AccountType.realSaving;
      case 15:
        return AccountType.savingCircle;
      default:
        return AccountType.cash;
    }
  }

  @override
  void write(BinaryWriter writer, AccountType obj) {
    switch (obj) {
      case AccountType.cash:
        writer.writeByte(0);
        break;
      case AccountType.bank:
        writer.writeByte(1);
        break;
      case AccountType.wallet:
        writer.writeByte(2);
        break;
      case AccountType.debitCard:
        writer.writeByte(3);
        break;
      case AccountType.debt:
        writer.writeByte(4);
        break;
      case AccountType.loan:
        writer.writeByte(5);
        break;
      case AccountType.creditCard:
        writer.writeByte(6);
        break;
      case AccountType.installment:
        writer.writeByte(7);
        break;
      case AccountType.investment:
        writer.writeByte(8);
        break;
      case AccountType.gold:
        writer.writeByte(9);
        break;
      case AccountType.stocks:
        writer.writeByte(10);
        break;
      case AccountType.certificates:
        writer.writeByte(11);
        break;
      case AccountType.lent:
        writer.writeByte(12);
        break;
      case AccountType.rosca:
        writer.writeByte(13);
        break;
      case AccountType.realSaving:
        writer.writeByte(14);
        break;
      case AccountType.savingCircle:
        writer.writeByte(15);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
