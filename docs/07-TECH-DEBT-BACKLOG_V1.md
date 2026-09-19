# Wafferly Tech Debt Backlog V1

**Status:** Non-blocking backlog
**Purpose:** Capture known quality/architecture debt that should not be lost while the Financial Foundation and Credit Card contracts are stabilized.

## TD-001 — Scheduling Logic Duplication

**Priority:** Medium
**Financial blocker:** No

The current codebase computes overlapping due/upcoming/overdue concepts in more than one place. `DebtsScreen` contains presentation-side state and monthly calculations that overlap with scheduling/read-model logic such as `ScheduleEvaluator` and `DebtQueryService`.

### Risk

A future change to recurrence or due-state rules can produce inconsistent results between the UI, Action Center, and debt read model.

### Target

Create one canonical domain/read-model path for temporal scheduling state and keep screens as consumers of that result rather than re-deriving schedule semantics.

### Acceptance

- One documented source for due/upcoming/overdue classification.
- Screen code does not reimplement recurrence math.
- Regression tests prove the same occurrence receives the same state across consumers.
