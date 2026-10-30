import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/financial_engine/execution/memory_financial_unit_of_work.dart';

void main() {
  test(
    'all rollback callbacks are attempted and the original error is preserved',
    () async {
      final calls = <String>[];
      final reportedErrors = <Object>[];
      final reportedStackTraces = <StackTrace>[];
      final originalError = StateError('original-operation');
      final originalStackTrace = StackTrace.current;
      Object? caughtError;
      StackTrace? caughtStackTrace;

      try {
        await MemoryFinancialUnitOfWork(
          onRollbackError: (error, stackTrace) {
            reportedErrors.add(error);
            reportedStackTraces.add(stackTrace);
          },
        ).execute((context) async {
          context.registerRollback(() async {
            calls.add('A');
            throw StateError('cleanup-A');
          });
          context.registerRollback(() async {
            calls.add('B');
            throw StateError('cleanup-B');
          });
          context.registerRollback(() async {
            calls.add('C');
          });

          Error.throwWithStackTrace(originalError, originalStackTrace);
        });
      } catch (error, stackTrace) {
        caughtError = error;
        caughtStackTrace = stackTrace;
      }

      expect(calls, <String>['C', 'B', 'A']);
      expect(caughtError, same(originalError));
      expect(caughtStackTrace, isNotNull);
      expect(caughtStackTrace.toString(), originalStackTrace.toString());
      expect(reportedErrors, hasLength(2));
      expect(reportedErrors[0].toString(), contains('cleanup-B'));
      expect(reportedErrors[1].toString(), contains('cleanup-A'));
      expect(reportedStackTraces, hasLength(2));
    },
  );

  test(
    'reporter failure does not mask the original error or stop remaining callbacks',
    () async {
      final calls = <String>[];
      final reportedErrors = <Object>[];
      final reportedStackTraces = <StackTrace>[];

      final originalError = StateError('original-operation');
      final originalStackTrace = StackTrace.current;

      Object? caughtError;
      StackTrace? caughtStackTrace;

      try {
        await MemoryFinancialUnitOfWork(
          onRollbackError: (error, stackTrace) {
            reportedErrors.add(error);
            reportedStackTraces.add(stackTrace);

            throw StateError('rollback-reporter-failure');
          },
        ).execute((context) async {
          context.registerRollback(() async {
            calls.add('A');
            throw StateError('cleanup-A');
          });

          context.registerRollback(() async {
            calls.add('B');
            throw StateError('cleanup-B');
          });

          Error.throwWithStackTrace(originalError, originalStackTrace);
        });
      } catch (error, stackTrace) {
        caughtError = error;
        caughtStackTrace = stackTrace;
      }

      expect(calls, <String>['B', 'A']);

      expect(reportedErrors, hasLength(2));
      expect(reportedErrors[0].toString(), contains('cleanup-B'));
      expect(reportedErrors[1].toString(), contains('cleanup-A'));

      expect(reportedStackTraces, hasLength(2));

      expect(caughtError, same(originalError));
      expect(caughtStackTrace, isNotNull);
      expect(caughtStackTrace.toString(), originalStackTrace.toString());
    },
  );
}
