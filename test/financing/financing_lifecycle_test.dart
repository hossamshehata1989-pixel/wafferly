import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/financing/domain/financing_lifecycle.dart';

void main() {
  const lifecycle = FinancingLifecycle();

  test('activates draft contract', () {
    final result = lifecycle.transition(
      currentState: FinancingLifecycleState.draft,
      event: FinancingLifecycleEvent.activate,
    );

    expect(result.fromState, FinancingLifecycleState.draft);
    expect(result.toState, FinancingLifecycleState.active);
  });

  test('cancels only before activation', () {
    final result = lifecycle.transition(
      currentState: FinancingLifecycleState.draft,
      event: FinancingLifecycleEvent.cancel,
    );

    expect(result.toState, FinancingLifecycleState.cancelled);
  });

  test('rejects cancellation of an active contract', () {
    expect(
      () => lifecycle.transition(
        currentState: FinancingLifecycleState.active,
        event: FinancingLifecycleEvent.cancel,
      ),
      throwsStateError,
    );
  });

  test('rejects settlement while applicable obligations remain', () {
    expect(
      () => lifecycle.transition(
        currentState: FinancingLifecycleState.active,
        event: FinancingLifecycleEvent.settle,
      ),
      throwsStateError,
    );
  });

  test('settles active contract only after obligations resolve', () {
    final result = lifecycle.transition(
      currentState: FinancingLifecycleState.active,
      event: FinancingLifecycleEvent.settle,
      allApplicableObligationsResolved: true,
    );

    expect(result.toState, FinancingLifecycleState.settled);
  });

  test('closes only after settlement and closure conditions', () {
    final result = lifecycle.transition(
      currentState: FinancingLifecycleState.settled,
      event: FinancingLifecycleEvent.close,
      postSettlementClosureConditionsSatisfied: true,
    );

    expect(result.toState, FinancingLifecycleState.closed);
  });

  test('rejects closing an active contract', () {
    expect(
      () => lifecycle.transition(
        currentState: FinancingLifecycleState.active,
        event: FinancingLifecycleEvent.close,
        postSettlementClosureConditionsSatisfied: true,
      ),
      throwsStateError,
    );
  });

  test('terminates an active contract without using cancellation', () {
    final result = lifecycle.transition(
      currentState: FinancingLifecycleState.active,
      event: FinancingLifecycleEvent.terminate,
    );

    expect(result.toState, FinancingLifecycleState.terminated);
  });

  test('terminal states reject further lifecycle events', () {
    for (final state in <String>[
      FinancingLifecycleState.cancelled,
      FinancingLifecycleState.terminated,
      FinancingLifecycleState.closed,
    ]) {
      expect(
        () => lifecycle.transition(
          currentState: state,
          event: FinancingLifecycleEvent.activate,
        ),
        throwsStateError,
      );
    }
  });

  test('normal lifecycle is Draft -> Active -> Settled -> Closed', () {
    final active = lifecycle.transition(
      currentState: FinancingLifecycleState.draft,
      event: FinancingLifecycleEvent.activate,
    );
    final settled = lifecycle.transition(
      currentState: active.toState,
      event: FinancingLifecycleEvent.settle,
      allApplicableObligationsResolved: true,
    );
    final closed = lifecycle.transition(
      currentState: settled.toState,
      event: FinancingLifecycleEvent.close,
      postSettlementClosureConditionsSatisfied: true,
    );

    expect(
      [active.toState, settled.toState, closed.toState],
      [
        FinancingLifecycleState.active,
        FinancingLifecycleState.settled,
        FinancingLifecycleState.closed,
      ],
    );
  });
}
