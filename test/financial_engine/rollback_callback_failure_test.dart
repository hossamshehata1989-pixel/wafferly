import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/financial_engine/execution/memory_financial_unit_of_work.dart';

void main() {
  test(
    'KNOWN_BUG: rollback stops at the first callback error and masks the original error',
    () async {
      final calls = <String>[];
      Object? caughtError;

      try {
        await const MemoryFinancialUnitOfWork().execute((context) async {
          context.registerRollback(() async {
            calls.add('A');
          });
          context.registerRollback(() async {
            calls.add('B');
            throw StateError('cleanup-B');
          });
          context.registerRollback(() async {
            calls.add('C');
          });

          throw StateError('original-operation');
        });
      } catch (error) {
        caughtError = error;
      }

      // The callbacks are run in reverse order: C, then B, then A.
      // Current behavior stops at B and never attempts A.
      expect(calls, <String>['C', 'B']);
      expect(caughtError, isA<StateError>());
      expect(caughtError.toString(), contains('cleanup-B'));
      expect(caughtError.toString(), isNot(contains('original-operation')));
    },
  );

  test(
    'M2 REGRESSION: all rollback callbacks are attempted and the original error is preserved',
    () async {
      final calls = <String>[];
      Object? caughtError;

      try {
        await const MemoryFinancialUnitOfWork().execute((context) async {
          context.registerRollback(() async {
            calls.add('A');
          });
          context.registerRollback(() async {
            calls.add('B');
            throw StateError('cleanup-B');
          });
          context.registerRollback(() async {
            calls.add('C');
          });

          throw StateError('original-operation');
        });
      } catch (error) {
        caughtError = error;
      }

      expect(calls, <String>['C', 'B', 'A']);
      expect(caughtError, isA<StateError>());
      expect(caughtError.toString(), contains('original-operation'));
    },
    skip: 'يتفعّل في M2 بعد عزل أخطاء callbacks والحفاظ على الخطأ الأصلي.',
  );
}
