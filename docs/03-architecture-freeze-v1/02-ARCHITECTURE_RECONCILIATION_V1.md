# Architecture Reconciliation V1

**Status:** Active Reconciliation
**Purpose:** Identify documentation that is ahead of, behind, or inconsistent with the current implementation.

## 1. Why This Exists

The repository contains multiple V4 architecture and audit documents created at different migration stages. Several describe the intended architecture correctly but state implementation status that no longer matches the current code snapshot.

This document prevents stale status claims from being mistaken for runtime evidence.

## 2. Reconciliation Rules

1. Accepted architectural intent remains relevant unless explicitly superseded.
2. Runtime code is the authority for implementation status.
3. A passing test proves the tested behavior, not an entire architecture claim.
4. When a document says "implemented" but code still contains an explicit `UnimplementedError`/`UnsupportedError` on the production path, the runtime implementation is treated as incomplete.

## 3. Key Reconciliations

### `docs/roadmap/ENGINE_STABILIZATION_PLAN.md`

**Document claim:** Expense, Income, Transfer, Correction, and Delete are supported.

**Current implementation evidence:** `DefaultFinancialPlanner` still throws `UnimplementedError` for `_planCorrection(...)` and `_planDeletion(...)`.

**Reconciled status:** Correction and deletion are architecturally accepted but implementation-incomplete.

**Action:** Update the roadmap status and add regression tests once implemented.

### `docs/AUDIT_REPORT_V4.md`

**Document claim:** Freeze readiness is `READY`.

**Current implementation evidence:** The latest code snapshot still contains writer bypasses, unimplemented correction/deletion planning, unimplemented balance adjustment, memory-only idempotency, and production allocation repository split.

**Reconciled status:** The architecture may be conceptually frozen, but implementation freeze readiness is not complete.

**Action:** Keep the document as historical audit material and reference this reconciliation for current implementation status until the audit is refreshed.

### `docs/ARCHITECTURE_FREEZE_SCHEDULED_MONEY_V4.md`

**Document intent:** Occurrences, execution history, transaction linkage, failed-occurrence handling, and occurrence-level idempotency are architectural requirements.

**Current implementation evidence:** The current occurrence model has pending/completed/skipped only; production provider does not filter commitment status; a completed one-time occurrence can be returned again; transaction ↔ occurrence back-reference is not currently persisted; idempotency is memory-only.

**Reconciled status:** Architectural target remains valid, but several contracts are not yet fully implemented.

**Action:** Use `05-SCHEDULED-MONEY-CONTRACT_V2.md` as the implementation checklist for this area.

### `docs/02-ADR/ADR-034-Exact-Money-Representation.md`

**Document claim:** Financial domain logic uses `Money` / `Decimal` and `double` remains only at legacy/persistence boundaries.

**Current implementation evidence:** Several financial-engine domain types still use `double` directly.

**Reconciled status:** ADR is accepted; migration is incomplete.

**Action:** No new financial domain feature should introduce additional internal monetary `double` usage. Migrate existing engine surfaces as part of stabilization.

### `docs/02-ADR/ADR-015-Financial Corrections.md`

**Document claim:** Financial correction/invalidation is the architecture for transaction edits/deletion.

**Current implementation evidence:** The planner entry points for correction/deletion are present but not implemented.

**Reconciled status:** Decision accepted; production capability incomplete.

**Action:** Implement according to the ADR instead of reintroducing CRUD semantics.

### `docs/02-ADR/ADR-019- Delete Operation Requires Transaction Snapshot.md`

**Document claim:** The Delete path was validated as fully executable.

**Current implementation evidence:** The current planner still has an unimplemented deletion planner method.

**Reconciled status:** The snapshot contract is still a valid architectural decision, but the "fully implemented" result statement is stale relative to the current snapshot.

### `docs/02-ADR/ADR-007 Financial Engine is the only writer of Financial Truth..md`

**Document intent:** Financial Engine is the only writer.

**Current implementation evidence:** Direct legacy transaction writes remain in `GoalDetailsScreen`, `TransactionEntryController` legacy path, and `TransactionApplicationService` legacy methods.

**Reconciled status:** This remains an accepted target invariant; enforcement/migration is incomplete.

## 4. Documentation That Should Remain Historical

The repository contains archived and copied ADR material under `docs/New folder` and `Archive` directories. These should not be treated as the active implementation contract unless an active document explicitly references them.

## 5. Current Primary References

Until the next architecture audit is completed, use this priority order:

1. Accepted ADRs that are not contradicted by a newer decision.
2. The current runtime code and tests for implementation status.
3. This reconciliation document for contradictions.
4. The V1 freeze pack in `docs/03-architecture-freeze-v1/` for pre-Credit-Card implementation gates.
5. Historical/archive documents only for context.
## V1.1 Credit Card Clarifications

The Credit Card contract now makes two previously implicit architecture decisions explicit:

1. `PaymentInstrument` is retained as a thin generic identity/linkage layer. It never owns a balance. `CreditCardProfile` is the Credit Card-specific profile attached to the instrument, while the linked Liability Account remains financial truth. A future hybrid product may link one instrument to multiple authoritative accounts without creating a duplicate balance ledger.

2. `Installment / Financing Contract` is the parent/source of truth for financing terms. `Commitment + Schedule` remains the mechanism for expressing future payment expectations, but an installment commitment is derived from the financing contract and does not become an independent owner of financing economics.

