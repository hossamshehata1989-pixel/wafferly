# Wafferly ADR Index — Audit Draft

> **Status: audit draft, not an authoritative canonical map.** Generated from filenames in the supplied project snapshot `ZIP(20261013-172645.zip)`. No ADR file was renamed, moved, deleted, or declared superseded by this patch. Filename alone is insufficient to decide which conflicting decision is current.

## Rules for using this index

- One ADR number must ultimately map to exactly one canonical decision file.
- A `REVISED` suffix is a review signal, not proof that the file is approved or supersedes the unsuffixed copy. Compare decision/status/date/content first.
- Preserve old decision text in `docs/02-ADR/_archive/` only after the canonical file and its references are confirmed in Git. Mark archived decisions `Superseded by: ADR-NNN` when that relationship is verified.
- Do not renumber ADRs 046/047 until all references in docs, code comments, tests, and the Architecture Decision Log are searched.
- Do not delete mojibake filenames automatically: first compare content hashes and references, then archive duplicates.

## Duplicate or suspicious numbers requiring human review

| ADR | Candidate filenames in snapshot | Safe action now |
|---:|---|---|
| 004 | `ADR-004 #U2014 Domain Mutation Execution.md`<br>`ADR-004 ΓÇö Domain Mutation Execution.md`<br>`ADR-004 Γò¼├┤Γö£├ºΓö£Γòó Domain Mutation Execution.md`<br>`ADR-004 — Domain Mutation Execution.md`<br>`ADR-004 ╬ô├ç├╢ Domain Mutation Execution.md`<br>`ADR-004 ╬ô├▓┬╝Γö£Γöñ╬ô├╢┬úΓö£┬║╬ô├╢┬ú╬ô├▓├│ Domain Mutation Execution.md` | Compare bytes/hash and references; archive only after Git baseline |
| 028 | `ADR-028 #U2014 Allocation Contract.md`<br>`ADR-028 ΓÇö Allocation Contract.md`<br>`ADR-028 Γò¼├┤Γö£├ºΓö£Γòó Allocation Contract.md`<br>`ADR-028 — Allocation Contract.md`<br>`ADR-028 ╬ô├ç├╢ Allocation Contract.md`<br>`ADR-028 ╬ô├▓┬╝Γö£Γöñ╬ô├╢┬úΓö£┬║╬ô├╢┬ú╬ô├▓├│ Allocation Contract.md` | Compare bytes/hash and references; archive only after Git baseline |
| 047 | `ADR-047-CREDIT-CARD-CHARGE-OPERATION.md`<br>`ADR-047-SCHEDULED-EXECUTION-ATOMICITY-AND-RECOVERY.md` | Resolve semantic collision; do not renumber before reference search |
| 050 | `ADR-050-CREDIT-CARD-STATEMENT-LIFECYCLE-AND-DUE-DATE-GENERATION-REVISED.md`<br>`ADR-050-CREDIT-CARD-STATEMENT-LIFECYCLE-AND-DUE-DATE-GENERATION.md` | Compare decision/status/date; designate canonical, archive others |
| 052 | `ADR-052-INSTALLMENT-FINANCING-CONTRACT-MODEL-REVISED.md`<br>`ADR-052-INSTALLMENT-FINANCING-CONTRACT-MODEL.md` | Compare decision/status/date; designate canonical, archive others |
| 053 | `ADR-053-INTEREST-CALCULATION-AND-INSTALLMENT-ALLOCATION-MODEL.md`<br>`ADR-053-INTEREST-CALCULATION-AND-INSTALLMENT-ALLOCATION-REVISED.md`<br>`ADR-053-INTEREST-CALCULATION-AND-INSTALLMENT-ALLOCATION.md` | Compare decision/status/date; designate canonical, archive others |
| 062 | `ADR-062-FINANCING-OVERPAYMENT-AND-EXCESS-PAYMENT.md`<br>`ADR-062-FINANCING-OVERPAYMENT-EXCESS-PAYMENT.md` | Compare decision/status/date; designate canonical, archive others |
| 071 | `ADR-071-CREDIT-CARD-PAYMENT-METHOD-CHANGE-BOUNDARY (1).md` | Compare bytes/hash and references; archive only after Git baseline |

## Complete filename inventory

| ADR | Filename |
|---:|---|
| 003 | `ADR-003-financial-operation-engine.md` |
| 004 ⚠️ | `ADR-004 #U2014 Domain Mutation Execution.md` |
| 004 ⚠️ | `ADR-004 ΓÇö Domain Mutation Execution.md` |
| 004 ⚠️ | `ADR-004 Γò¼├┤Γö£├ºΓö£Γòó Domain Mutation Execution.md` |
| 004 ⚠️ | `ADR-004 — Domain Mutation Execution.md` |
| 004 ⚠️ | `ADR-004 ╬ô├ç├╢ Domain Mutation Execution.md` |
| 004 ⚠️ | `ADR-004 ╬ô├▓┬╝Γö£Γöñ╬ô├╢┬úΓö£┬║╬ô├╢┬ú╬ô├▓├│ Domain Mutation Execution.md` |
| 005 | `ADR-005 Finish Financial Engine Before Dynamic Categories.md` |
| 006 | `ADR-06 Financial Categories vs UI Categories.md` |
| 007 | `ADR-007 Financial Engine is the only writer of Financial Truth..md` |
| 008 | `ADR-008 Rich Financial Operations.md` |
| 009 | `ADR-009 Financial Command Model.md` |
| 010 | `ADR-0010-Financial Transaction Record.md` |
| 011 | `ADR-0011-Infrastructure Adapter Responsibility.md` |
| 012 | `ADR-0012 Financial Execution Plan Completeness.md` |
| 013 | `ADR-0013-Entry Session State.md` |
| 014 | `ADR-0014-Financial Operation Resolution Pipeline.md` |
| 015 | `ADR-0015-Financial Corrections.md` |
| 016 | `ADR-0016- Financial Write Model & Ledger Projection.md` |
| 017 | `ADR-017-Complete Ledger Integration into Financial Engine.md` |
| 018 | `ADR-018 -Transaction Deletion Semantics (Draft).md` |
| 019 | `ADR-019- Delete Operation Requires Transaction Snapshot.md` |
| 020 | `ADR-020-Wafferly UI Design System Foundation.md` |
| 021 | `ADR-021-Financial Truth Boundary & Opening Balance Modeling.md` |
| 022 | `ADR-022-Planning Engine Core Architecture.md` |
| 023 | `ADR-023- Planning Domain Model.md` |
| 024 | `ADR-024- Allocation Lifecycle & Ownership - Copy.md` |
| 025 | `ADR-025-Planning Policies & Domain Guards.md` |
| 026 | `ADR-026-PlanningOperation Contract.md` |
| 027 | `ADR-027-Interaction Platform.md` |
| 028 ⚠️ | `ADR-028 #U2014 Allocation Contract.md` |
| 028 ⚠️ | `ADR-028 ΓÇö Allocation Contract.md` |
| 028 ⚠️ | `ADR-028 Γò¼├┤Γö£├ºΓö£Γòó Allocation Contract.md` |
| 028 ⚠️ | `ADR-028 — Allocation Contract.md` |
| 028 ⚠️ | `ADR-028 ╬ô├ç├╢ Allocation Contract.md` |
| 028 ⚠️ | `ADR-028 ╬ô├▓┬╝Γö£Γöñ╬ô├╢┬úΓö£┬║╬ô├╢┬ú╬ô├▓├│ Allocation Contract.md` |
| 029 | `ADR-029-Planning Execution Plan.md` |
| 030 | `ADR-30-Money Reservation Architecture.md` |
| 032 | `ADR-032-Debt-Domain-Architecture.md` |
| 033 | `ADR-033-Account-Classification-and-Legacy-Group-Migration.md` |
| 034 | `ADR-034-Exact-Money-Representation.md` |
| 041 | `ADR-041-TRACEABILITY-BOUNDARY.md` |
| 042 | `ADR-042-EFFECTIVE-FINANCIAL-TRUTH-READ-BOUNDARY.md` |
| 043 | `ADR-043-MONEY-CONSISTENCY-DOMAIN-BOUNDARY.md` |
| 044 | `ADR-044-MONEY-CONSISTENCY-M1-CLOSED.md` |
| 045 | `ADR-045-MONEY-BOUNDARY-M2-HARDENING.md` |
| 046 | `ADR-046-MONTHLY-DUE-DATE-ROLLOVER-POLICY.md` |
| 047 ⚠️ | `ADR-047-CREDIT-CARD-CHARGE-OPERATION.md` |
| 047 ⚠️ | `ADR-047-SCHEDULED-EXECUTION-ATOMICITY-AND-RECOVERY.md` |
| 048 | `ADR-048 — Credit Card Charge Operation.md` |
| 049 | `ADR-049-CREDIT-LIMIT-DOMAIN-GUARD.md` |
| 050 ⚠️ | `ADR-050-CREDIT-CARD-STATEMENT-LIFECYCLE-AND-DUE-DATE-GENERATION-REVISED.md` |
| 050 ⚠️ | `ADR-050-CREDIT-CARD-STATEMENT-LIFECYCLE-AND-DUE-DATE-GENERATION.md` |
| 051 | `ADR-051-CREDIT-CARD-PAYMENT-SETTLEMENT-OPERATION.md` |
| 052 ⚠️ | `ADR-052-INSTALLMENT-FINANCING-CONTRACT-MODEL-REVISED.md` |
| 052 ⚠️ | `ADR-052-INSTALLMENT-FINANCING-CONTRACT-MODEL.md` |
| 053 ⚠️ | `ADR-053-INTEREST-CALCULATION-AND-INSTALLMENT-ALLOCATION-MODEL.md` |
| 053 ⚠️ | `ADR-053-INTEREST-CALCULATION-AND-INSTALLMENT-ALLOCATION-REVISED.md` |
| 053 ⚠️ | `ADR-053-INTEREST-CALCULATION-AND-INSTALLMENT-ALLOCATION.md` |
| 054 | `ADR-054-PAYMENT-ALLOCATION-ORDER.md` |
| 055 | `ADR-055-MULTI-INSTALLMENT-PAYMENT-ALLOCATION.md` |
| 056 | `ADR-056-EARLY-SETTLEMENT-PREPAYMENT-POLICY.md` |
| 057 | `ADR-057-LATE-PAYMENT-FEE-POLICY.md` |
| 058 | `ADR-058-FINANCING-RESCHEDULING-RESTRUCTURING-POLICY.md` |
| 059 | `ADR-059-FINANCING-CONTRACT-REPLACEMENT-POLICY.md` |
| 060 | `ADR-060-FINANCING-CONTRACT-SETTLEMENT-AND-CLOSURE.md` |
| 061 | `ADR-061-FINANCING-CONTRACT-CANCELLATION-TERMINATION.md` |
| 062 ⚠️ | `ADR-062-FINANCING-OVERPAYMENT-AND-EXCESS-PAYMENT.md` |
| 062 ⚠️ | `ADR-062-FINANCING-OVERPAYMENT-EXCESS-PAYMENT.md` |
| 063 | `ADR-063-FINANCING-PAYMENT-REVERSAL-REFUND.md` |
| 064 | `ADR-064-FINANCING-DEFAULT-DELINQUENCY-LIFECYCLE.md` |
| 065 | `ADR-065-FINANCING-WAIVER-FORGIVENESS.md` |
| 066 | `ADR-066-FINANCING-FINANCIAL-EFFECTS-BOUNDARY.md` |
| 067 | `ADR-067-FINANCING-OPERATION-IDEMPOTENCY.md` |
| 068 | `ADR-068-FINANCING-AUDIT-TRACEABILITY-BOUNDARY.md` |
| 069 | `ADR-069-CREDIT-CARD-STATEMENT-INSTALLMENT-RELATIONSHIP.md` |
| 070 | `ADR-070-CREDIT-CARD-FINANCING-CONVERSION-BOUNDARY.md` |
| 071 ⚠️ | `ADR-071-CREDIT-CARD-PAYMENT-METHOD-CHANGE-BOUNDARY (1).md` |
| 072 | `ADR-072-CREDIT-CARD-LINKED-BANK-ACCOUNT.md` |
| 073 | `ADR-073-CREDIT-CARD-PAYMENT-AMOUNT-SELECTION.md` |

## Baseline required before cleanup

1. Create a Git commit for the exact working tree before applying cleanup changes.
2. Record `git rev-parse HEAD`, date, and the latest actual `flutter test` / `flutter analyze` results in the project status log.
3. Search references before moving or renaming ADR files:
   ```powershell
   git grep -n -E "ADR[- ]?(046|047|050|052|053|062|071)|Scheduled Execution Atomicity|Credit Card Charge Operation" -- .
   ```
4. Compare candidate files before choosing a canonical version:
   ```powershell
   Get-FileHash "docs/02-ADR/ADR-050-CREDIT-CARD-STATEMENT-LIFECYCLE-AND-DUE-DATE-GENERATION.md"
   Get-FileHash "docs/02-ADR/ADR-050-CREDIT-CARD-STATEMENT-LIFECYCLE-AND-DUE-DATE-GENERATION-REVISED.md"
   ```
5. After an approved mapping exists, move noncanonical files into `docs/02-ADR/_archive/` and update links in a separate patch.
6. Run `git diff --check`, documentation reference checks, and the full test suite after the moves.

## Scope deliberately excluded

- No source-code changes.
- No automatic ADR renumbering.
- No deleting `.diff` files or mojibake files.
- No claim that the current snapshot has passed tests.


## Conflict audit findings (2026-10-15)

See [`ADR-CONFLICT-RESOLUTION-AUDIT.md`](ADR-CONFLICT-RESOLUTION-AUDIT.md) for evidence-based review. No source ADR is declared canonical solely from its filename.

- **046/047:** scheduled-execution recovery file has a 047 filename but an ADR-046 title; keep unresolved pending approved renumbering and reference search.
- **050:** revised candidate adds ADR-069 statement/installment relationship semantics; leading candidate, not yet canonical.
- **052:** revised candidate expands the contract schema and changes the charge-operation reference; verify implementation and links.
- **053:** short Accepted policy file conflicts in status/coverage with two detailed Proposed -> Implementation files; reconcile explicitly rather than deleting either.
- **062:** short Accepted file expressly establishes strict rejection of non-zero unallocated payment; longer Proposed file is contextual and must not override that rule.

These recommendations are based on the supplied snapshot only. Do not move/archive files until the actual working-tree baseline and reference checks are complete.
