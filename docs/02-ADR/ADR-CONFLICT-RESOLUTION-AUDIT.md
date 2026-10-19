# ADR Conflict Resolution Audit — Phase B

**Baseline inspected:** `ZIP(20261013-172645).zip` (project snapshot supplied in this conversation)
**Purpose:** Evidence-based recommendations without moving, renaming, deleting, or rewriting source ADRs.
**Important:** This audit is not a replacement for a Git baseline. Verify against the actual working tree before canonicalization.

## 1. ADR-046 / ADR-047 — numbering collision

Observed in `docs/02-ADR/`:

- `ADR-046-MONTHLY-DUE-DATE-ROLLOVER-POLICY.md` title is **ADR-046 — Monthly / Periodic Due-Date Rollover Policy**, status **Accepted**.
- `ADR-047-CREDIT-CARD-CHARGE-OPERATION.md` title is **ADR-047 — Credit Card Charge Operation**, status **Proposed -> Implementation**.
- `ADR-047-SCHEDULED-EXECUTION-ATOMICITY-AND-RECOVERY.md` has filename number **047**, but internal title **ADR-046 — Scheduled Execution Atomicity and Recovery**, status **Accepted**.
- `docs/ADR-046-SCHEDULED-EXECUTION-ATOMICITY-AND-RECOVERY.md` is a duplicate-content copy of the scheduled-execution document (same 3,799 bytes in this snapshot).
- `docs/ADR-047-070-REFERENCE-GRAPH-AUDIT.md` explicitly maps **ADR-047** to Credit Card Charge Operation.

**Conclusion:** The scheduled-execution document is the collision. Do not renumber automatically: search references across docs/code/tests and confirm the new number with the project owner. Keep both copies unchanged until that mapping is approved.

## 2. ADR-050 — statement lifecycle

Candidates:
- `ADR-050-CREDIT-CARD-STATEMENT-LIFECYCLE-AND-DUE-DATE-GENERATION.md` — 7,159 bytes.
- `ADR-050-CREDIT-CARD-STATEMENT-LIFECYCLE-AND-DUE-DATE-GENERATION-REVISED.md` — 8,551 bytes.

The revised file is not byte-identical. It adds a section describing the relationship between installment schedule, due date, statement cycle, and statement contribution, and adds ADR-069 to related references.

**Recommendation:** Treat the revised file as the leading candidate because it incorporates ADR-069 relationship semantics, but verify the entire decision and implementation before marking canonical. Archive the older file only after links are migrated and checked.

## 3. ADR-052 — installment financing contract model

Candidates:
- `ADR-052-INSTALLMENT-FINANCING-CONTRACT-MODEL.md` — 11,943 bytes.
- `ADR-052-INSTALLMENT-FINANCING-CONTRACT-MODEL-REVISED.md` — 15,190 bytes.

The revised candidate changes the charge-operation reference from ADR-048 to ADR-047 and expands the contract schema boundary (contractId, originReference, recurrence/frequency, first due date, policy reference, lifecycle state, and traceability metadata). Both files say **Proposed -> Implementation** in this snapshot.

**Recommendation:** The revised file is the stronger candidate, but do not archive the original until code fields and ADR-047/048 references have been searched and reconciled. Status alone does not prove final acceptance.

## 4. ADR-053 — interest calculation and installment allocation

Candidates:
- `ADR-053-INTEREST-CALCULATION-AND-INSTALLMENT-ALLOCATION-MODEL.md` — 2,298 bytes, status **Accepted**.
- `ADR-053-INTEREST-CALCULATION-AND-INSTALLMENT-ALLOCATION.md` — 11,759 bytes, status **Proposed -> Implementation**.
- `ADR-053-INTEREST-CALCULATION-AND-INSTALLMENT-ALLOCATION-REVISED.md` — 11,646 bytes, status **Proposed -> Implementation**.

The two long versions differ; the revised one adds ADR-069 statement-inclusion boundaries. The short Accepted file appears to state a compact set of decisions, not a full replacement for the detailed model.

**Recommendation:** Do not pick one file as the sole canonical source yet. Treat the short Accepted file as evidence of accepted policy and compare its complete decision set against the detailed versions. The final canonical ADR may need a deliberate consolidation with history preserved.

## 5. ADR-062 — strict overpayment rejection

Candidates:
- `ADR-062-FINANCING-OVERPAYMENT-AND-EXCESS-PAYMENT.md` — 560 bytes; status **Accepted**; explicitly requires strict rejection of any non-zero `unallocatedAmount`.
- `ADR-062-FINANCING-OVERPAYMENT-EXCESS-PAYMENT.md` — 2,818 bytes; status **Proposed -> Implementation** and provides longer context.

**Recommendation:** The short Accepted file is the strongest evidence for the governing policy: strict overpayment rejection, with `unallocatedAmount` calculation-only and not persisted as shadow truth. The longer file must not override this rule. Search references and preserve useful context before any archive/merge.

## 6. Safe execution order

1. Commit the exact working tree and record `git rev-parse HEAD`.
2. Search ADR references, filenames, titles, and quoted links for 046, 047, 048, 050, 052, 053, 062.
3. Confirm the scheduled-execution ADR's new number with the project owner; do not silently take the next number.
4. Approve one canonical path per collision in a mapping table.
5. In a separate patch, update links and move superseded copies to `docs/02-ADR/_archive/`; do not delete originals in the first cleanup pass.
6. Run `git diff --check`, broken-link/reference checks, and actual project test/analyze commands.

## Evidence limitation

This audit inspected filenames, file lengths, internal titles/statuses, and textual differences in the supplied ZIP. It did not run Flutter tests, verify the live Git working tree, or prove which ADR text is implemented in code. No source ADR has been changed by this patch.

## Resolution Update (2026-10-17)

The scheduled-execution numbering collision has been resolved in the current working tree:

- ADR-046 remains Monthly Due-Date Rollover Policy.
- ADR-047 remains Credit Card Charge Operation.
- Scheduled Execution Atomicity and Recovery now uses the filename and internal title ADR-076.
- The duplicate scheduled-execution document and duplicate ADR-048 credit-card document were preserved under `docs/02-ADR/_archive/`.
- The original ADR-076 decision status remains **Accepted**. This update records the file/reference cleanup and does not constitute a new decision approval.
