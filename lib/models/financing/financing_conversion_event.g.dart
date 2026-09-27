// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'financing_conversion_event.dart';

class FinancingConversionEventAdapter
    extends TypeAdapter<FinancingConversionEvent> {
  @override
  final int typeId = 114;

  @override
  FinancingConversionEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++)
        reader.readByte(): reader.read(),
    };
    return FinancingConversionEvent(
      conversionId: fields[0] as String,
      originChargeId: fields[1] as String,
      contractId: fields[2] as String,
      scheduleId: fields[3] as String,
      scheduleRuleId: fields[4] as String,
      status: fields[5] as String,
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, FinancingConversionEvent obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.conversionId)
      ..writeByte(1)
      ..write(obj.originChargeId)
      ..writeByte(2)
      ..write(obj.contractId)
      ..writeByte(3)
      ..write(obj.scheduleId)
      ..writeByte(4)
      ..write(obj.scheduleRuleId)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt);
  }
}
