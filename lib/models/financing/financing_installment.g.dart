part of 'financing_installment.dart';

class FinancingInstallmentAdapter extends TypeAdapter<FinancingInstallment> {
  @override
  final int typeId = 112;

  @override
  FinancingInstallment read(BinaryReader reader) {
    final n = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return FinancingInstallment(
      installmentId: fields[0] as String,
      contractId: fields[1] as String,
      scheduleId: fields[2] as String,
      occurrenceId: fields[3] as String?,
      sequence: fields[4] as int,
      dueDate: fields[5] as DateTime,
      openingPrincipalValue: fields[6] as String,
      principalComponentValue: fields[7] as String,
      interestComponentValue: fields[8] as String,
      feesValue: fields[9] as String,
      amountValue: fields[10] as String,
      status: fields[11] as String,
    );
  }

  @override
  void write(BinaryWriter writer, FinancingInstallment obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)..write(obj.installmentId)
      ..writeByte(1)..write(obj.contractId)
      ..writeByte(2)..write(obj.scheduleId)
      ..writeByte(3)..write(obj.occurrenceId)
      ..writeByte(4)..write(obj.sequence)
      ..writeByte(5)..write(obj.dueDate)
      ..writeByte(6)..write(obj.openingPrincipalValue)
      ..writeByte(7)..write(obj.principalComponentValue)
      ..writeByte(8)..write(obj.interestComponentValue)
      ..writeByte(9)..write(obj.feesValue)
      ..writeByte(10)..write(obj.amountValue)
      ..writeByte(11)..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinancingInstallmentAdapter && typeId == other.typeId;
}
