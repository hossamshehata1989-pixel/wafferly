import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:wafferly/core/money/money.dart';
import 'package:wafferly/models/commitment.dart';
import 'package:wafferly/models/enums/commitment_amount_mode.dart';
import 'package:wafferly/models/enums/commitment_status.dart';
import 'package:wafferly/models/enums/commitment_type.dart';

/// Legacy shape used only to create the bytes produced by the pre-DEBT-01
/// adapter. The persisted field layout intentionally matches CommitmentAdapter
/// field-for-field, including field 4 as a double.
class _LegacyCommitmentRecord {
  const _LegacyCommitmentRecord({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required this.amount,
    required this.amountMode,
    required this.scheduleRuleId,
    this.sourceAccountId,
    this.destinationAccountId,
    this.liabilityAccountId,
    this.notes,
    this.isArchived = false,
  });

  final String id;
  final String title;
  final CommitmentType type;
  final CommitmentStatus status;
  final double amount;
  final CommitmentAmountMode amountMode;
  final String? sourceAccountId;
  final String? destinationAccountId;
  final String scheduleRuleId;
  final String? liabilityAccountId;
  final String? notes;
  final bool isArchived;
}

class _LegacyCommitmentAdapter extends TypeAdapter<_LegacyCommitmentRecord> {
  @override
  final int typeId = 96;

  @override
  _LegacyCommitmentRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return _LegacyCommitmentRecord(
      id: fields[0] as String,
      title: fields[1] as String,
      type: fields[2] as CommitmentType,
      status: fields[3] as CommitmentStatus,
      amount: fields[4] as double,
      amountMode: fields[5] as CommitmentAmountMode,
      scheduleRuleId: fields[8] as String,
      sourceAccountId: fields[6] as String?,
      destinationAccountId: fields[7] as String?,
      liabilityAccountId: fields[9] as String?,
      notes: fields[10] as String?,
      isArchived: fields[11] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, _LegacyCommitmentRecord obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.amountMode)
      ..writeByte(6)
      ..write(obj.sourceAccountId)
      ..writeByte(7)
      ..write(obj.destinationAccountId)
      ..writeByte(8)
      ..write(obj.scheduleRuleId)
      ..writeByte(9)
      ..write(obj.liabilityAccountId)
      ..writeByte(10)
      ..write(obj.notes)
      ..writeByte(11)
      ..write(obj.isArchived);
  }
}

void _registerCommitmentDependencies() {
  Hive.registerAdapter(CommitmentTypeAdapter());
  Hive.registerAdapter(CommitmentStatusAdapter());
  Hive.registerAdapter(CommitmentAmountModeAdapter());
}

void main() {
  late Directory testDirectory;

  setUp(() async {
    testDirectory = await Directory.systemTemp.createTemp(
      'wafferly_debt01_commitment_hive_',
    );
    Hive.init(testDirectory.path);
    Hive.resetAdapters();
  });

  tearDown(() async {
    await Hive.close();
    Hive.resetAdapters();
    if (await testDirectory.exists()) {
      await testDirectory.delete(recursive: true);
    }
  });

  test('reads a legacy Hive double into Money without changing field 4', () async {
    _registerCommitmentDependencies();
    Hive.registerAdapter(_LegacyCommitmentAdapter());

    final legacyBox = await Hive.openBox<dynamic>('commitments');
    await legacyBox.put(
      'legacy-1',
      const _LegacyCommitmentRecord(
        id: 'legacy-1',
        title: 'Legacy Commitment',
        type: CommitmentType.expense,
        status: CommitmentStatus.active,
        amount: 125.50,
        amountMode: CommitmentAmountMode.fixed,
        scheduleRuleId: 'schedule-1',
      ),
    );
    await Hive.close();

    Hive.resetAdapters();
    _registerCommitmentDependencies();
    Hive.registerAdapter(CommitmentAdapter());

    final migratedBox = await Hive.openBox<Commitment>('commitments');
    final commitment = migratedBox.get('legacy-1');

    expect(commitment, isNotNull);
    expect(commitment!.amount, Money.parse('125.5'));
    expect(commitment.amount.toDouble(), 125.5);
  });

  test('writes Money back to Hive field 4 as a legacy-compatible double', () async {
    _registerCommitmentDependencies();
    Hive.registerAdapter(CommitmentAdapter());

    final box = await Hive.openBox<Commitment>('commitments');
    await box.put(
      'money-1',
      Commitment(
        id: 'money-1',
        title: 'Money Commitment',
        type: CommitmentType.expense,
        status: CommitmentStatus.active,
        amount: Money.parse('125.50'),
        amountMode: CommitmentAmountMode.fixed,
        scheduleRuleId: 'schedule-1',
      ),
    );
    await Hive.close();

    Hive.resetAdapters();
    _registerCommitmentDependencies();
    Hive.registerAdapter(_LegacyCommitmentAdapter());

    final legacyBox = await Hive.openBox<_LegacyCommitmentRecord>('commitments');
    final persisted = legacyBox.get('money-1');

    expect(persisted, isNotNull);
    expect(persisted!.amount, 125.5);
  });
}
