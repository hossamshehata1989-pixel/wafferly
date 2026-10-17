# Wafferly ADR Canonicalization — Phase D

This patch is deliberately non-destructive by default. It addresses only byte-identical duplicates verified in the 2026-10-13 project snapshot.

## Verified duplicate sets

- ADR-004 Domain Mutation Execution: 6 files, SHA-256 `7f034cc9ce8a73518525dfa505d171ad614b26a6e1c5f09a662fa6a03b876331`, 4,556 bytes each.
- ADR-028 Allocation Contract: 6 files, SHA-256 `9b40006b75d479f89d1c0a48e2b1f3a8e6e74b0900d22e99d8a02fbc231d3343`, 4,790 bytes each.

Canonical candidates are the correctly encoded names using an em dash:
- `docs/02-ADR/ADR-004 — Domain Mutation Execution.md`
- `docs/02-ADR/ADR-028 — Allocation Contract.md`

The other five names in each set appear to be encoding-corrupted copies. This is based on exact byte equality, not filename similarity alone.

## Safe application

1. Commit or stash all current changes.
2. Copy `tools/adr-canonicalize-phase-d.ps1` to the repository root or run it from the repository root.
3. First run in dry-run mode:
   `powershell -ExecutionPolicy Bypass -File .\tools\adr-canonicalize-phase-d.ps1`
4. Review the report. The script checks that Git is clean, checks exact hashes, and searches repository text for references to duplicate filenames. It will refuse to move a duplicate if references are found.
5. Only after reviewing the dry-run output, explicitly apply:
   `$env:APPLY_ADR_CANONICALIZATION='1'; powershell -ExecutionPolicy Bypass -File .\tools\adr-canonicalize-phase-d.ps1`

The script archives duplicates under `docs/02-ADR/_archive/phase-d/`, preserving the original filename. It does not delete files, edit decision contents, change financial rules, or rename ADR numbers. If any duplicate filename is referenced elsewhere, it stops before moving that file; update references in a separate reviewed change first.

## Scope limitation

This patch only handles the two verified duplicate sets above. ADR-046/047, ADR-050/052/053/062 and all other conflicts remain unchanged pending separate content/reference review. This patch has not been run against your working tree and cannot prove the repository is clean or tests pass there.
