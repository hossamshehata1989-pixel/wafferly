import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:wafferly/financial_engine/execution/financial_execution_summary.dart';
import 'package:wafferly/financial_engine/idempotency/hive_idempotency_store.dart';
import 'package:wafferly/financial_engine/idempotency/idempotency_record.dart';
import 'package:wafferly/financial_engine/results/operation_result.dart';

void main() {
  late Directory testDirectory;
  late Box<Map> box;
  late HiveIdempotencyStore store;

  setUpAll(() async {
    testDirectory = await Directory.systemTemp.createTemp(
      'wafferly_hive_idempotency_validation_',
    );
    Hive.init(testDirectory.path);
    box = await Hive.openBox<Map>('idempotency_validation');
    store = HiveIdempotencyStore(box);
  });

  setUp(() async {
    await box.clear();
  });

  tearDownAll(() async {
    await box.close();
    await testDirectory.delete(recursive: true);
  });

  OperationSucceeded successfulResult() => OperationSucceeded(
    summary: FinancialExecutionSummary(
      createdTransactionIds: const <String>['txn-1'],
      balanceChanges: const <String, double>{'wallet': -10},
      createdMutationIds: const <String>['mutation-1'],
    ),
  );

  Map<String, dynamic> legacyV1Record() => <String, dynamic>{
    'version': 1,
    'resultType': 'operationSucceeded',
    'summary': <String, dynamic>{
      'createdTransactionIds': <String>['legacy-txn'],
      'balanceChanges': <String, double>{'wallet': -5},
      'createdMutationIds': <String>['legacy-mutation'],
    },
  };

  test(
    'new durable records are always written as V2 with fingerprint',
    () async {
      await store.saveRecord(
        IdempotencyRecord(
          key: 'v2-key',
          requestFingerprint: 'fingerprint-123',
          result: successfulResult(),
        ),
      );

      final raw = box.get('v2-key')!;
      expect(raw['version'], 2);
      expect(raw['requestFingerprint'], 'fingerprint-123');

      final restored = await store.findRecord('v2-key');
      expect(restored?.requestFingerprint, 'fingerprint-123');
      expect(restored?.result, isA<OperationSucceeded>());
    },
  );

  test('new durable records cannot be written without a fingerprint', () async {
    await expectLater(
      store.saveRecord(
        IdempotencyRecord(
          key: 'missing-fingerprint',
          result: successfulResult(),
        ),
      ),
      throwsA(isA<StateError>()),
    );
    expect(box.containsKey('missing-fingerprint'), isFalse);
  });

  test('V2 record with missing fingerprint is rejected as corrupt', () async {
    final raw = legacyV1Record()..['version'] = 2;
    await box.put('v2-missing-fingerprint', raw);

    await expectLater(
      store.findRecord('v2-missing-fingerprint'),
      throwsA(isA<StateError>()),
    );
    expect(box.get('v2-missing-fingerprint'), equals(raw));
  });

  test('V2 record with empty fingerprint is rejected as corrupt', () async {
    final raw = legacyV1Record()
      ..['version'] = 2
      ..['requestFingerprint'] = '   ';
    await box.put('v2-empty-fingerprint', raw);

    await expectLater(
      store.findRecord('v2-empty-fingerprint'),
      throwsA(isA<StateError>()),
    );
    expect(box.get('v2-empty-fingerprint'), equals(raw));
  });

  test(
    'V2 record with non-string fingerprint is rejected as corrupt',
    () async {
      final raw = legacyV1Record()
        ..['version'] = 2
        ..['requestFingerprint'] = 123;
      await box.put('v2-invalid-fingerprint', raw);

      await expectLater(
        store.findRecord('v2-invalid-fingerprint'),
        throwsA(isA<StateError>()),
      );
      expect(box.get('v2-invalid-fingerprint'), equals(raw));
    },
  );

  test('legacy V1 record remains readable and unchanged', () async {
    final raw = legacyV1Record();
    await box.put('legacy-v1-key', raw);

    final restored = await store.findRecord('legacy-v1-key');

    expect(restored, isNotNull);
    expect(restored!.requestFingerprint, isNull);
    expect(restored.result, isA<OperationSucceeded>());
    expect(box.get('legacy-v1-key'), equals(raw));
  });
}
