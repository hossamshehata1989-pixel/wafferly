// GENERATED-LIKE FILE — intentionally checked in to keep this schema change
// independent from build_runner ordering.

part of 'financing_contract.dart';

class FinancingContractAdapter extends TypeAdapter<FinancingContract> {
  @override
  final int typeId = 110;

  @override
  FinancingContract read(BinaryReader reader) {
    final n = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return FinancingContract(
      contractId: fields[0] as String,
      liabilityAccountId: fields[1] as String,
      originReference: fields[2] as String,
      principalValue: fields[3] as String,
      installmentCount: fields[4] as int,
      paymentFrequency: fields[5] as String,
      firstDueDate: fields[6] as DateTime,
      interestPolicyId: fields[7] as String?,
      lifecycleState: fields[8] as String,
      predecessorContractId: fields[9] as String?,
      effectiveDate: fields[10] as DateTime,
      createdAt: fields[11] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, FinancingContract obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)..write(obj.contractId)
      ..writeByte(1)..write(obj.liabilityAccountId)
      ..writeByte(2)..write(obj.originReference)
      ..writeByte(3)..write(obj.principalValue)
      ..writeByte(4)..write(obj.installmentCount)
      ..writeByte(5)..write(obj.paymentFrequency)
      ..writeByte(6)..write(obj.firstDueDate)
      ..writeByte(7)..write(obj.interestPolicyId)
      ..writeByte(8)..write(obj.lifecycleState)
      ..writeByte(9)..write(obj.predecessorContractId)
      ..writeByte(10)..write(obj.effectiveDate)
      ..writeByte(11)..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinancingContractAdapter && typeId == other.typeId;
}
