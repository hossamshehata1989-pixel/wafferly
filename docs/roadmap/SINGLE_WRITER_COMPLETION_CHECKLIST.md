# Single Writer — Completion Checklist

**Date:** 2026-09-22
**Status:** Tier 1 Migration Gate CLOSED / Overall Single Writer OPEN
**Authority:** ADR-036 — Single Writer Boundary and Remaining Financial Writers

## 1. Tier 1 — Migration Gate

### Financial Reality flows

- [x] Expense routed through `FinancialOperationEngine`.
- [x] Income routed through `FinancialOperationEngine`.
- [x] Transfer routed through `FinancialOperationEngine`.
- [x] Reserved Goal → Saving routed through `GoalTransferOperation`.
- [x] Non-reserved Goal → Saving routed through `GoalSavingTransferOperation`.

### Boundary verification

- [x] Reserved Goal transfer has no direct `TransactionService.instance.addTransaction` writer in the UI flow.
- [x] Non-reserved Goal → Saving has no direct transaction writer in the UI flow.
- [x] Non-reserved Goal → Saving uses `FinancialOperationEngine`.
- [x] Non-reserved Goal → Saving has dedicated structural/domain validation.
- [x] Invalid destination is rejected without financial side effects.
- [x] Insufficient balance is rejected without financial side effects.

### Regression verification

- [x] Targeted Goal Saving Transfer pipeline tests passed.
- [x] Single Writer architecture boundary tests passed.
- [x] Full `flutter test` passed: **119/119 tests**.
- [x] No new Financial Reality bypass was identified by the migration verification.

**Tier 1 result: CLOSED.**

---

## 2. Tier 2 — Remaining Production Financial Reality Work

These items are intentionally not marked complete. Each requires its own domain decision and regression coverage before final Single Writer closure.

### A. Generic Transaction Writer

- [x] Inventory every production caller of the generic transaction API; the only active production caller was the `TransactionEntryController` fallback.
- [ ] Enumerate every transaction subtype it can represent.
- [ ] Map each subtype to an explicit canonical operation or document why it belongs to another state boundary.
- [x] Remove the active production fallback to the generic transaction writer; the generic API remains as a compatibility surface pending subtype mapping/classification.
- [x] Add an architecture/boundary test preventing `TransactionEntryController` from falling back to the generic transaction writer.

### B. Balance Adjustment

- [ ] Define what a Balance Adjustment means in Financial Reality.
- [ ] Define source of truth and accounting/journal semantics.
- [ ] Define domain guards and policy/confirmation behavior.
- [ ] Define idempotency requirements.
- [ ] Implement canonical operation and planner/executor path.
- [ ] Migrate production caller(s).
- [ ] Add success/failure/rollback regression tests.
- [ ] Re-audit remaining balance writers.

### C. Correction / Invalidation

- [ ] Define correction versus reversal versus invalidation semantics.
- [ ] Define immutable history requirements.
- [ ] Define ledger/journal behavior.
- [ ] Define idempotency and traceability requirements.
- [ ] Implement canonical operation(s).
- [ ] Migrate production caller(s).
- [ ] Add regression tests for correction, invalidation, and rollback.
- [ ] Re-audit transaction mutation paths.

### D. Legacy Allocation / Reserved Money State

- [ ] Prove state equivalence between legacy stores and the Planning Engine repository.
- [ ] Identify remaining production readers.
- [ ] Remove obsolete production dependencies/readers after equivalence is proven.
- [ ] Retire or explicitly classify legacy stores.
- [ ] Add architecture tests preventing reintroduction of a second planning-state writer.

### E. Final Single Writer Closure Audit

- [ ] Re-run the production active-writer audit after A–D.
- [ ] Verify every production Financial Reality mutation has exactly one canonical owner.
- [ ] Verify all remaining non-production writers have no production callers.
- [ ] Update ADR-036 with final classifications.
- [ ] Run full regression suite.
- [ ] Only then mark **Overall Single Writer — CLOSED**.

---

## 3. Explicitly Out of Scope for the Single Writer Financial Reality Gate

- Planning State mutations owned by `PlanningEngine`.
- Goal Activity history/audit persistence owned by `GoalActivityService` / its adapter, where it does not itself become the owner of Financial Reality.
- Development/test/sandbox-only writers with no production callers.
- Persistence adapters that only persist mutations already planned by the canonical engine/operation.

---

## 4. Definition of Done

### Tier 1 Migration Gate

**DONE:** All currently identified Financial Reality flows with established behavior-equivalent canonical operations are migrated and verified.

### Overall Single Writer

**NOT YET DONE:** All remaining production Financial Reality writers must first be either:

1. migrated to a canonical operation with regression coverage; or
2. explicitly classified by an accepted ADR as belonging outside the Financial Reality boundary.

No writer should be removed or rerouted merely to make this checklist green.
