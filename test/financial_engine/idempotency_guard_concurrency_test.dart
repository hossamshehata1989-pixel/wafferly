import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/financial_engine/idempotency/idempotency_guard.dart';
import 'package:wafferly/financial_engine/memory/memory_idempotency_store.dart';
import 'package:wafferly/financial_engine/results/operation_result.dart';

void main() {
  late IdempotencyGuard guard;

  setUp(() {
    guard = IdempotencyGuard(
      store: MemoryIdempotencyStore(),
    );
  });

  test(
    'concurrent requests with same key and fingerprint share one execution',
    () async {
      final release = Completer<OperationResult>();
      final result = OperationFailed(
        error: StateError('Expected test failure'),
      );

      var executions = 0;

      final first = guard.run(
        key: 'concurrent-key',
        requestFingerprint: 'fingerprint-A',
        action: () async {
          executions++;
          return release.future;
        },
      );

      final second = guard.run(
        key: 'concurrent-key',
        requestFingerprint: 'fingerprint-A',
        action: () async {
          executions++;
          return OperationRejected(reason: 'Must not execute');
        },
      );

      await Future<void>.delayed(Duration.zero);

      expect(executions, 1);

      release.complete(result);

      expect(await first, same(result));
      expect(await second, same(result));
      expect(executions, 1);
    },
  );

  test(
    'same key with different fingerprint is rejected while execution is active',
    () async {
      final release = Completer<OperationResult>();

      final first = guard.run(
        key: 'conflict-key',
        requestFingerprint: 'fingerprint-A',
        action: () => release.future,
      );

      await expectLater(
        guard.run(
          key: 'conflict-key',
          requestFingerprint: 'fingerprint-B',
          action: () async => OperationRejected(
            reason: 'Must not execute',
          ),
        ),
        throwsA(isA<IdempotencyConflictException>()),
      );

      release.complete(
        OperationRejected(reason: 'First execution completed'),
      );

      await first;
    },
  );

  test(
    'failed execution does not prevent retry with the same key',
    () async {
      var executions = 0;

      final first = await guard.run(
        key: 'retry-key',
        requestFingerprint: 'fingerprint-A',
        action: () async {
          executions++;
          return OperationFailed(
            error: StateError('First attempt failed'),
          );
        },
      );

      final second = await guard.run(
        key: 'retry-key',
        requestFingerprint: 'fingerprint-A',
        action: () async {
          executions++;
          return OperationRejected(reason: 'Second attempt executed');
        },
      );

      expect(first, isA<OperationFailed>());
      expect(second, isA<OperationRejected>());
      expect(executions, 2);
    },
  );
}