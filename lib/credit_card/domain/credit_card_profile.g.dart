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
    );
  }

  @override
  void write(BinaryWriter writer, CreditCardProfile obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.accountId)
      ..writeByte(2)
      ..write(obj.creditLimitValue);
  }
}
