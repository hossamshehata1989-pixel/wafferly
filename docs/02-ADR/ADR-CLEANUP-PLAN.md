# ADR Cleanup Plan — Safe Execution Order

## Phase A — Inventory (this patch)
- Add `docs/02-ADR/ADR-INDEX.md` as a non-authoritative inventory.
- Preserve every original file unchanged.

## Phase B — Establish baseline
- Create a Git commit of the current working tree.
- Record commit hash and real test/analyze output in a separate status log.
- Confirm the active project tree contains no untracked source edits that must be retained.

## Phase C — Resolve semantic collisions
- Read `ADR-CONFLICT-RESOLUTION-AUDIT.md` first; its recommendations are provisional until checked against the current working tree.
1. ADR-046/047: resolve the collision between monthly due-date rollover, credit-card charge operation, and scheduled execution atomicity/recovery. Search all references before renumbering any document.
2. ADR-050/052/053/062: compare full text, status, dates, and references. `REVISED` does not automatically mean accepted/canonical.
3. ADR-004/028/048: compare the mojibake-named copies with readable names using hashes and content diffs.
4. ADR-071 `(1)`: verify whether another ADR-071 exists elsewhere in the repository before renaming.
5. `.diff` files: determine whether they are historical patch artifacts or referenced documentation; do not delete solely by extension.

## Phase D — Canonicalize
- Declare one canonical filename per ADR number in the index.
- Move verified superseded copies into `docs/02-ADR/_archive/`.
- Add `Status`, `Decision`, `Consequences`, and `Superseded by` metadata only where supported by the actual document history.
- Update `Architecture Decision Log.md`, cross-links, and references in docs/tests.

## Phase E — Verify
- `git diff --check`
- Search for broken links and old paths.
- Run the full Flutter test suite and `flutter analyze`.
- Commit cleanup separately from behavioral code changes.

**Important:** This plan intentionally avoids guessing the canonical version from filename ordering. Financial and architectural decisions must not be silently changed during documentation cleanup.
