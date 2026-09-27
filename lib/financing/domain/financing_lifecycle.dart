/// Pure financing-contract lifecycle state machine.
///
/// This models contractual state only. It does not mutate Account,
/// Transaction, Ledger, Balance, or any FinancialOperationEngine state.
/// Financial effects must be executed through the Financial Engine boundary.
class FinancingLifecycleState {
  static const draft = 'draft';
  static const active = 'active';
  static const settled = 'settled';
  static const closed = 'closed';
  static const cancelled = 'cancelled';
  static const terminated = 'terminated';

  const FinancingLifecycleState._();
}

enum FinancingLifecycleEvent {
  activate,
  cancel,
  settle,
  close,
  terminate,
}

class FinancingLifecycleTransition {
  final String fromState;
  final FinancingLifecycleEvent event;
  final String toState;

  const FinancingLifecycleTransition({
    required this.fromState,
    required this.event,
    required this.toState,
  });
}

/// Pure transition engine for ADR-060/ADR-061 financing contract lifecycle.
class FinancingLifecycle {
  const FinancingLifecycle();

  FinancingLifecycleTransition transition({
    required String currentState,
    required FinancingLifecycleEvent event,
    bool allApplicableObligationsResolved = false,
    bool postSettlementClosureConditionsSatisfied = false,
  }) {
    final state = currentState.trim().toLowerCase();

    switch (event) {
      case FinancingLifecycleEvent.activate:
        _requireState(state, FinancingLifecycleState.draft, event);
        return _transition(state, event, FinancingLifecycleState.active);

      case FinancingLifecycleEvent.cancel:
        // Cancellation is intentionally limited to pre-activation state.
        _requireState(state, FinancingLifecycleState.draft, event);
        return _transition(state, event, FinancingLifecycleState.cancelled);

      case FinancingLifecycleEvent.terminate:
        // An active contract ended before normal completion is terminated,
        // not cancelled. Historical state remains immutable.
        _requireState(state, FinancingLifecycleState.active, event);
        return _transition(state, event, FinancingLifecycleState.terminated);

      case FinancingLifecycleEvent.settle:
        _requireState(state, FinancingLifecycleState.active, event);
        if (!allApplicableObligationsResolved) {
          throw StateError(
            'Financing contract cannot settle while applicable obligations remain unresolved.',
          );
        }
        return _transition(state, event, FinancingLifecycleState.settled);

      case FinancingLifecycleEvent.close:
        _requireState(state, FinancingLifecycleState.settled, event);
        if (!postSettlementClosureConditionsSatisfied) {
          throw StateError(
            'Financing contract cannot close before post-settlement closure conditions are satisfied.',
          );
        }
        return _transition(state, event, FinancingLifecycleState.closed);
    }
  }

  FinancingLifecycleTransition _transition(
    String from,
    FinancingLifecycleEvent event,
    String to,
  ) {
    return FinancingLifecycleTransition(
      fromState: from,
      event: event,
      toState: to,
    );
  }

  void _requireState(
    String current,
    String expected,
    FinancingLifecycleEvent event,
  ) {
    if (current != expected) {
      throw StateError(
        'Lifecycle event ${event.name} is not allowed from state "$current"; '
        'expected "$expected".',
      );
    }
  }
}
