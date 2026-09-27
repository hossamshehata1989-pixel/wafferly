part of 'statement_installment_contribution.dart';

class StatementInstallmentContributionAdapter
    extends TypeAdapter<StatementInstallmentContribution> {
  @override
  final int typeId = 113;

  @override
  StatementInstallmentContribution read(BinaryReader reader) {
    final n = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return StatementInstallmentContribution(
      contributionId: fields[0] as String,
      statementId: fields[1] as String,
      contractId: fields[2] as String,
      installmentId: fields[3] as String,
      principalValue: fields[4] as String,
      interestValue: fields[5] as String,
      feesValue: fields[6] as String,
      contributionValue: fields[7] as String,
      createdAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, StatementInstallmentContribution obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)..write(obj.contributionId)
      ..writeByte(1)..write(obj.statementId)
      ..writeByte(2)..write(obj.contractId)
      ..writeByte(3)..write(obj.installmentId)
      ..writeByte(4)..write(obj.principalValue)
      ..writeByte(5)..write(obj.interestValue)
      ..writeByte(6)..write(obj.feesValue)
      ..writeByte(7)..write(obj.contributionValue)
      ..writeByte(8)..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatementInstallmentContributionAdapter &&
          typeId == other.typeId;
}
