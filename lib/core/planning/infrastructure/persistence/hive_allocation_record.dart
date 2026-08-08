import 'package:hive/hive.dart';

import '../../entities/allocation.dart';
import '../../value_objects/allocation_status.dart';
import '../../value_objects/planning_source_type.dart';

/// Persistence representation of the Planning Allocation.
///
/// This type belongs to Infrastructure and must not be used by the
/// Planning Engine itself.
final class HiveAllocationRecord {
  const HiveAllocationRecord({
    required this.id,
    required this.sourceId,
    required this.sourceTypeIndex,
    required this.accountId,
    required this.amount,
    required this.statusIndex,
    required this.version,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String sourceId;
  final int sourceTypeIndex;
  final String accountId;
  final double amount;
  final int statusIndex;
  final int version;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory HiveAllocationRecord.fromDomain(Allocation allocation) {
    return HiveAllocationRecord(
      id: allocation.id,
      sourceId: allocation.sourceId,
      sourceTypeIndex: allocation.sourceType.index,
      accountId: allocation.accountId,
      amount: allocation.amount,
      statusIndex: allocation.status.index,
      version: allocation.version,
      createdAt: allocation.createdAt,
      updatedAt: allocation.updatedAt,
    );
  }

  Allocation toDomain() {
    return Allocation(
      id: id,
      sourceId: sourceId,
      sourceType: PlanningSourceType.values[sourceTypeIndex],
      accountId: accountId,
      amount: amount,
      status: AllocationStatus.values[statusIndex],
      version: version,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Hive adapter for the Planning Allocation persistence record.
///
/// TypeId 97 is intentionally separate from the legacy Allocation
/// adapter (typeId 80).
final class HiveAllocationRecordAdapter
    extends TypeAdapter<HiveAllocationRecord> {
  @override
  final int typeId = 97;

  @override
  HiveAllocationRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return HiveAllocationRecord(
      id: fields[0] as String,
      sourceId: fields[1] as String,
      sourceTypeIndex: fields[2] as int,
      accountId: fields[3] as String,
      amount: fields[4] as double,
      statusIndex: fields[5] as int,
      version: fields[6] as int,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveAllocationRecord obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sourceId)
      ..writeByte(2)
      ..write(obj.sourceTypeIndex)
      ..writeByte(3)
      ..write(obj.accountId)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.statusIndex)
      ..writeByte(6)
      ..write(obj.version)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveAllocationRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
