// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credit_card_profile.dart';

class CreditCardProfileAdapter extends TypeAdapter<CreditCardProfile> {
  @override
  final int typeId = 100;

  @override
  CreditCardProfile read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < fieldCount; i++)
        reader.readByte(): reader.read(),
    };

    return CreditCardProfile(
      id: fields[0] as String,
      accountId: fields[1] as String,
      creditLimitValue: fields[2] as String,
      cardKind: fields[3] as String? ?? 'physical',
      cardNetwork: fields[4] as String?,
      statementDay: fields[5] as int?,
      paymentDueDay: fields[6] as int?,
      linkedDebitCardAccountId: fields[7] as String?,
      annualFeeValue: fields[8] as String?,
      cardVisual: fields[9] as String? ?? 'classic',
    );
  }

  @override
  void write(BinaryWriter writer, CreditCardProfile obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.accountId)
      ..writeByte(2)
      ..write(obj.creditLimitValue)
      ..writeByte(3)
      ..write(obj.cardKind)
      ..writeByte(4)
      ..write(obj.cardNetwork)
      ..writeByte(5)
      ..write(obj.statementDay)
      ..writeByte(6)
      ..write(obj.paymentDueDay)
      ..writeByte(7)
      ..write(obj.linkedDebitCardAccountId)
      ..writeByte(8)
      ..write(obj.annualFeeValue)
      ..writeByte(9)
      ..write(obj.cardVisual);
  }
}
