import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/screens/planning/goal_transfer_idempotency_manager.dart';

void main() {
  test('an unchanged failed goal transfer reuses key and occurredAt', () {
    var clockCalls = 0;
    final manager = GoalTransferIdempotencyManager(
      clock: () => DateTime(2026, 10, 31).add(Duration(seconds: clockCalls++)),
    );

    GoalTransferIdempotencyIdentity obtain({double amount = 500}) {
      return manager.obtain(
        operationType: 'goal-transfer',
        goalId: 'goal-1',
        sourceAccountId: 'wallet',
        savingAccountId: 'savings',
        amount: amount,
      );
    }

    final first = obtain();
    final retry = obtain();

    expect(retry.idempotencyKey, first.idempotencyKey);
    expect(retry.occurredAt, first.occurredAt);
    expect(clockCalls, 1);
  });

  test('a changed goal transfer request gets a new identity', () {
    var clockCalls = 0;
    final manager = GoalTransferIdempotencyManager(
      clock: () => DateTime(2026, 10, 31).add(Duration(seconds: clockCalls++)),
    );

    final first = manager.obtain(
      operationType: 'goal-transfer',
      goalId: 'goal-1',
      sourceAccountId: 'wallet',
      savingAccountId: 'savings',
      amount: 500,
    );
    final changed = manager.obtain(
      operationType: 'goal-transfer',
      goalId: 'goal-1',
      sourceAccountId: 'wallet',
      savingAccountId: 'savings',
      amount: 400,
    );

    expect(changed.idempotencyKey, isNot(first.idempotencyKey));
    expect(changed.occurredAt, isNot(first.occurredAt));
  });

  test(
    'a completed goal transfer allows a new identical intentional transfer',
    () {
      var clockCalls = 0;
      final manager = GoalTransferIdempotencyManager(
        clock: () =>
            DateTime(2026, 10, 31).add(Duration(seconds: clockCalls++)),
      );

      GoalTransferIdempotencyIdentity obtain() => manager.obtain(
        operationType: 'goal-saving-transfer',
        goalId: 'goal-2',
        sourceAccountId: 'cash',
        savingAccountId: 'savings',
        amount: 250,
      );

      final first = obtain();
      manager.markSucceeded(first);
      final second = obtain();

      expect(second.idempotencyKey, isNot(first.idempotencyKey));
      expect(second.occurredAt, isNot(first.occurredAt));
    },
  );

  test('different goal transfer operation types have separate identities', () {
    final manager = GoalTransferIdempotencyManager(
      clock: () => DateTime(2026, 10, 31),
    );

    final reservedTransfer = manager.obtain(
      operationType: 'goal-transfer',
      goalId: 'goal-1',
      sourceAccountId: 'wallet',
      savingAccountId: 'savings',
      amount: 100,
    );
    final contribution = manager.obtain(
      operationType: 'goal-saving-transfer',
      goalId: 'goal-1',
      sourceAccountId: 'wallet',
      savingAccountId: 'savings',
      amount: 100,
    );

    expect(contribution.idempotencyKey, isNot(reservedTransfer.idempotencyKey));
  });
}
