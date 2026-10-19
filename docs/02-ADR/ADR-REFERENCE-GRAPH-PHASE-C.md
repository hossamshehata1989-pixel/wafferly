# ADR Reference Graph & Canonicalization Map — Phase C

**Evidence baseline:** `ZIP(20261013-172645.zip` supplied snapshot. This is a report-only patch; it does not rename, move, delete, or rewrite any source ADR.

## Key outcomes

1. `ADR-047-CREDIT-CARD-CHARGE-OPERATION.md` is explicitly mapped as ADR-047 in `docs/ADR-047-070-REFERENCE-GRAPH-AUDIT.md` (13 textual mentions of ADR-047 in that audit). Do not renumber it.
2. Historical snapshot finding: `ADR-047-SCHEDULED-EXECUTION-ATOMICITY-AND-RECOVERY.md` had internal title ADR-046 and an exact-content duplicate. The collision was resolved on 2026-10-17 by renaming the active document to ADR-076 and archiving the duplicate; see the Resolution Update below.
3. ADR-004 and ADR-028 each have six filename variants with identical SHA-256 hashes within their respective groups. These are byte-identical duplicates in this snapshot; still do not remove them until link/path references and the Git baseline are secured.
4. ADR-050 revised is the leading candidate, not yet canonical; ADR-052 revised is the leading candidate, not yet canonical; ADR-053 needs consolidation because a short Accepted file coexists with two longer implementation-stage files; ADR-062 Accepted short file governs strict overpayment rejection.
5. `ADR-071-CREDIT-CARD-PAYMENT-METHOD-CHANGE-BOUNDARY (1).md` is the only ADR-071 file found in `docs/02-ADR` in this snapshot, but the `(1)` suffix alone is insufficient reason to rename it.

## Reference counts across the snapshot

Counts below are textual mentions across markdown, text, Dart, YAML, JSON and diff files; they are discovery aids, not proof that every mention is a live link. Search is case-insensitive and matches `ADR-0NN`/`ADR_NNN`/`ADR NNN`.

| ADR | Mentions | Files mentioning it |
|---:|---:|---:|
| 046 | 26 | 15 |
| 047 | 40 | 16 |
| 048 | 8 | 3 |
| 050 | 33 | 17 |
| 052 | 31 | 19 |
| 053 | 33 | 17 |
| 062 | 9 | 8 |
| 071 | 3 | 2 |

## High-priority reference files

### `ADR-047-070-REFERENCE-GRAPH-AUDIT.md`
- `docs/ADR-047-070-REFERENCE-GRAPH-AUDIT.md`

### `ADR-050-CREDIT-CARD-STATEMENT-LIFECYCLE-AND-DUE-DATE-GENERATION`
- `docs/02-ADR/ADR-050-CREDIT-CARD-STATEMENT-LIFECYCLE-AND-DUE-DATE-GENERATION-REVISED.md`
- `docs/02-ADR/ADR-050-CREDIT-CARD-STATEMENT-LIFECYCLE-AND-DUE-DATE-GENERATION.md`

### `ADR-052-INSTALLMENT-FINANCING-CONTRACT-MODEL`
- `docs/02-ADR/ADR-052-INSTALLMENT-FINANCING-CONTRACT-MODEL-REVISED.md`
- `docs/02-ADR/ADR-052-INSTALLMENT-FINANCING-CONTRACT-MODEL.md`

### `ADR-053-INTEREST-CALCULATION-AND-INSTALLMENT-ALLOCATION`
- `docs/02-ADR/ADR-053-INTEREST-CALCULATION-AND-INSTALLMENT-ALLOCATION-MODEL.md`
- `docs/02-ADR/ADR-053-INTEREST-CALCULATION-AND-INSTALLMENT-ALLOCATION-REVISED.md`
- `docs/02-ADR/ADR-053-INTEREST-CALCULATION-AND-INSTALLMENT-ALLOCATION.md`

### `ADR-062-FINANCING-OVERPAYMENT`
- `docs/02-ADR/ADR-062-FINANCING-OVERPAYMENT-AND-EXCESS-PAYMENT.md`
- `docs/02-ADR/ADR-062-FINANCING-OVERPAYMENT-EXCESS-PAYMENT.md`

## Byte-identical filename groups

### ADR-004
- SHA-256 `7f034cc9ce8a73518525dfa505d171ad614b26a6e1c5f09a662fa6a03b876331` — 6 files
  - `docs/02-ADR/ADR-004 #U2014 Domain Mutation Execution.md`
  - `docs/02-ADR/ADR-004 ΓÇö Domain Mutation Execution.md`
  - `docs/02-ADR/ADR-004 Γò¼├┤Γö£├ºΓö£Γòó Domain Mutation Execution.md`
  - `docs/02-ADR/ADR-004 — Domain Mutation Execution.md`
  - `docs/02-ADR/ADR-004 ╬ô├ç├╢ Domain Mutation Execution.md`
  - `docs/02-ADR/ADR-004 ╬ô├▓┬╝Γö£Γöñ╬ô├╢┬úΓö£┬║╬ô├╢┬ú╬ô├▓├│ Domain Mutation Execution.md`

### ADR-028
- SHA-256 `9b40006b75d479f89d1c0a48e2b1f3a8e6e74b0900d22e99d8a02fbc231d3343` — 6 files
  - `docs/02-ADR/ADR-028 #U2014 Allocation Contract.md`
  - `docs/02-ADR/ADR-028 ΓÇö Allocation Contract.md`
  - `docs/02-ADR/ADR-028 Γò¼├┤Γö£├ºΓö£Γòó Allocation Contract.md`
  - `docs/02-ADR/ADR-028 — Allocation Contract.md`
  - `docs/02-ADR/ADR-028 ╬ô├ç├╢ Allocation Contract.md`
  - `docs/02-ADR/ADR-028 ╬ô├▓┬╝Γö£Γöñ╬ô├╢┬úΓö£┬║╬ô├╢┬ú╬ô├▓├│ Allocation Contract.md`

## Canonicalization mapping and remaining proposals

| ADR / concern | Proposed target | Source files to preserve until migration | Approval status |
|---|---|---|---|
| Scheduled execution atomicity/recovery | ADR-076: `docs/02-ADR/ADR-076-SCHEDULED-EXECUTION-ATOMICITY-AND-RECOVERY.md` | `docs/02-ADR/_archive/ADR-046-DUPLICATE-SCHEDULED-EXECUTION-ATOMICITY-AND-RECOVERY.md` | Resolved 2026-10-17; duplicate preserved in archive |
| 047 credit-card charge | Keep ADR-047 | `docs/02-ADR/ADR-047-CREDIT-CARD-CHARGE-OPERATION.md` and `.diff` | Strong evidence; verify code/docs references |
| 050 statement lifecycle | Prefer revised file for consolidation | Both 050 files | Provisional |
| 052 financing contract | Prefer revised file for consolidation | Both 052 files | Provisional |
| 053 interest/allocation | Consolidate detailed model around Accepted policy, preserve both detailed histories | All three 053 files | Pending policy-by-policy comparison |
| 062 overpayment | Keep short Accepted file as governing decision; retain long version as historical context until links updated | Both 062 files | Strong status evidence; no file move yet |
| 004 / 028 mojibake copies | One readable canonical file per group; archive byte-identical variants after reference migration | All six variants in each group | Hash equality verified in snapshot; Git baseline and reference checks pending |
| 071 `(1)` suffix | Keep unchanged until repository-wide duplicate/reference check | Existing file | Pending |

## Safe next operations

1. In the live repository, run `git status --short` and commit the exact working tree before documentation mutations.
2. Search all tracked and untracked files for each old filename and internal ADR number, including Markdown links, relative paths, code comments, tests, and scripts.
3. Approve the new number for scheduled execution; do not assume the next numeric ADR is free.
4. Perform canonicalization as a separate patch: update references first, move confirmed duplicate copies to `docs/02-ADR/_archive/`, and add `Superseded by` only when the history supports it.
5. Validate with `git diff --check`, broken-link scan, and `flutter test` / `flutter analyze` as applicable.

## Limitations

- This report inspects the supplied ZIP snapshot only, not the user’s live working tree or Git commit.
- Counts are textual references, not semantic link validation.
- No Flutter tests were run.
- No source ADR was modified by this patch.

## Resolution Update (2026-10-17)

The scheduled-execution ADR has been renumbered to ADR-076 in the current working tree. References that identify the active scheduled-execution document must use `ADR-076-SCHEDULED-EXECUTION-ATOMICITY-AND-RECOVERY.md`.

The former duplicate was preserved in `docs/02-ADR/_archive/`. Historical reference counts and findings above describe the original evidence snapshot and have not been retroactively rewritten.

This update does not resolve the separate ADR-004, ADR-028, ADR-050, ADR-052, ADR-053, ADR-062, or ADR-071 findings.
