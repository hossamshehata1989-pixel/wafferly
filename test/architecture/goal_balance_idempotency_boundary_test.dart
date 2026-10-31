import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'goal transfer UI obtains one stable identity for each pending request',
    () {
      final screen = File(
        'lib/screens/planning/goal_details_screen.dart',
      ).readAsStringSync();

      expect(screen, contains('GoalTransferIdempotencyManager'));
      expect(screen, contains("operationType: 'goal-transfer'"));
      expect(screen, contains("operationType: 'goal-saving-transfer'"));
      expect(screen, contains('idempotencyKey: identity.idempotencyKey'));
      expect(screen, contains('occurredAt: identity.occurredAt'));
      expect(
        screen,
        contains('_goalTransferIdempotency.markSucceeded(identity)'),
      );
      expect(screen, isNot(contains('occurredAt.microsecondsSinceEpoch')));
    },
  );

  test('balance reconciliation requires caller-owned key and timestamp', () {
    final service = File(
      'lib/application/accounts/account_transaction_service.dart',
    ).readAsStringSync();
    final start = service.indexOf('Future<void> createBalanceReconciliation');
    final end = service.indexOf('/// Legacy name retained temporarily', start);

    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));
    final method = service.substring(start, end);

    expect(method, contains('required DateTime occurredAt'));
    expect(method, contains('required String idempotencyKey'));
    expect(
      method,
      contains('ExecutionContext(idempotencyKey: idempotencyKey)'),
    );
    expect(method, contains('occurredAt: occurredAt'));
    expect(method, isNot(contains('DateTime.now()')));
  });

  test('legacy reconciliation alias forwards the caller identity', () {
    final service = File(
      'lib/application/accounts/account_transaction_service.dart',
    ).readAsStringSync();

    final start = service.indexOf('Future<void> createBalanceAdjustment');

    expect(start, greaterThanOrEqualTo(0));

    // The legacy alias is the final method in this service.
    final method = service.substring(start);

    expect(method, contains('required DateTime occurredAt'));
    expect(method, contains('required String idempotencyKey'));
    expect(method, contains('occurredAt: occurredAt'));
    expect(method, contains('idempotencyKey: idempotencyKey'));
  });

  test('opening balance keeps its account-scoped identity', () {
    final service = File(
      'lib/application/accounts/account_transaction_service.dart',
    ).readAsStringSync();

    expect(
      service,
      contains("idempotencyKey: 'opening-balance-\${account.id}'"),
    );
  });
}
