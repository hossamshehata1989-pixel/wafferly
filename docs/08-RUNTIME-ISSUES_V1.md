# Wafferly Runtime Issues V1

**Status:** Non-financial runtime backlog
**Evidence basis:** Latest terminal run associated with commit `76428f2`.

## RT-001 — Missing Savings Illustration Asset

**Observed:** Runtime reported a missing asset for:

```text
assets/illustrations/financial_groups/savings_outlined.svg
```

**Impact:** Asset loading fails at runtime even though the APK builds successfully.

**Action:** Restore the asset or remove/update the reference, then run the affected screen flow to confirm no asset exception remains.

## RT-002 — Skipped Frames During Runtime

**Observed:** The latest run logged skipped frames during startup/runtime.

**Impact:** Indicates a performance/runtime concern, but it is not currently established as a Financial Engine correctness issue.

**Action:** After RT-001 is resolved, reproduce with profiling/dev tools and identify whether the skips are caused by debug-mode startup work, asset loading, synchronous initialization, or an actual UI performance regression.

## Scope Rule

These runtime issues are tracked separately from the Credit Card financial gate. They must not be forgotten, but they do not block financial-domain implementation unless later evidence shows they affect financial correctness or user data integrity.
