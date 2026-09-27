part of 'financing_schedule.dart';

class FinancingScheduleAdapter extends TypeAdapter<FinancingSchedule> {
  @override
  final int typeId = 111;

  @override
  FinancingSchedule read(BinaryReader reader) {
    final n = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return FinancingSchedule(
      scheduleId: fields[0] as String,
      contractId: fields[1] as String,
      scheduleRuleId: fields[2] as String,
      installmentCount: fields[3] as int,
      status: fields[4] as String,
      createdAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, FinancingSchedule obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)..write(obj.scheduleId)
      ..writeByte(1)..write(obj.contractId)
      ..writeByte(2)..write(obj.scheduleRuleId)
      ..writeByte(3)..write(obj.installmentCount)
      ..writeByte(4)..write(obj.status)
      ..writeByte(5)..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinancingScheduleAdapter && typeId == other.typeId;
}
