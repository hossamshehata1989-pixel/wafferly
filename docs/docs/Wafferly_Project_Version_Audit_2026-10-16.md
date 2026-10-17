# Wafferly — Project Version & Architecture Audit

**Reviewed snapshot:** `ZIP(20261016-220555).zip`  
**Comparison snapshot:** `ZIP(20261013-172645.zip`  
**Audit type:** static source/documentation inspection only  
**No source files were modified.**

## Executive conclusion

The newest source snapshot supplied for this audit is the **16 October 2026 ZIP**. It is newer than the 13 October archive: it adds the Drift/SMS architecture proposals and migration inventory, adds `CreditCardCycleResolver` and a credit-card list projection service with tests, and changes several credit-card projection/guard/interpreter/test files.

However, the runtime represented by this ZIP is **still the Hive-based implementation**, not the proposed SQLite/Drift architecture:

- `pubspec.yaml` depends on `hive` and `hive_flutter`; it does not include `drift`, `sqlite3`, or Supabase client packages.
- `lib/main.dart` initializes Hive, registers adapters, and opens the existing boxes.
- `lib/bootstrap/financial_engine_bootstrap.dart` wires `DefaultFinancialExecutor` to `MemoryFinancialUnitOfWork`.
- `docs/02-ADR/ADR-075-HIVE-TO-SQLITE-DRIFT-MIGRATION.md` has status **Proposed for final acceptance** and explicitly says approval of the ADR does not mean Drift is implemented.

So the answer to “which version are we actually following?” is:

1. **Latest source snapshot for review:** `ZIP(20261016-220555.zip)`.
2. **Current runtime persistence in that snapshot:** Hive + financial operation engine + Hive-backed adapters/ports, with a memory rollback wrapper—not Drift.
3. **Intended target architecture in the newer ADRs:** local-first SQLite/Drift as the sole local source of truth, with optional cloud sync; one real database transaction for the complete financial write boundary; no dual-write or silent Hive fallback. This target has **not** been implemented in the reviewed snapshot.
4. **Git identity:** not verifiable from this ZIP because `.git` is absent. The earlier terminal output showed `HEAD=778f725c24f6d681efbd2508931146032837d6fd` with uncommitted changes, but I cannot prove this archive exactly matches that working tree.

## What changed between the 13 and 16 October archives

The archives differ in more than file naming. The 16 October archive includes these relevant additions:

- `docs/02-ADR/ADR-074-SMS-IFUP-V1-INTEGRATION.md`
- `docs/02-ADR/ADR-075-HIVE-TO-SQLITE-DRIFT-MIGRATION.md`
- `docs/02-ADR/ADR-INDEX.md`
- `docs/02-ADR/ADR-CLEANUP-PLAN.md`
- `docs/02-ADR/ADR-CONFLICT-RESOLUTION-AUDIT.md`
- `docs/02-ADR/ADR-REFERENCE-GRAPH-PHASE-C.md`
- `docs/implementation/HIVE_TO_DRIFT_MIGRATION_INVENTORY.md`
- `lib/application/credit_card/credit_card_cycle_resolver.dart`
- `lib/application/credit_card/credit_cards_list_projection_service.dart`
- matching tests for the cycle resolver and credit-card list projection.

Several existing card charge/due-projection, domain-guard, interpreter, and test files also differ. The 16 October archive omits some files that were in the 13 October archive, including `AGENTS.md` and `Wafferly_Project_Rules.md`; this ZIP omission does **not** prove that those files were deleted from the user's actual working tree.

## Architecture reality check

### Persistence and financial atomicity — highest priority

The active app is still Hive-based. `main.dart` opens boxes for accounts, transactions, card profiles, financing contracts/schedules/installments, ledger records, corrections, invalidations, idempotency, traceability, planning allocations, and scheduled execution state.

Production bootstrap currently uses `MemoryFinancialUnitOfWork`. Its implementation records compensating rollback callbacks and executes them after a caught exception. This is useful error compensation but is **not a durable relational transaction** and does not offer one SQLite commit covering all relevant state. `FinancialOperationEngine` remembers successful idempotency results and writes traceability after executor success, separately from the financial mutation write boundary. That leaves crash windows that must be addressed before calling the full financial operation atomic.

The migration ADR correctly names the target:

- SQLite through Drift is the only active local authoritative store after cutover.
- No Hive/Drift dual-write and no silent Hive fallback.
- A real Drift transaction must cover all durable effects belonging to one logical financial operation, including the relevant financial records, ledger/journal state, and idempotency outcome according to the operation contract.
- Existing development/test data is disposable by default before external testing; a one-time personal export/import is optional, not a production migration runner.

### Idempotency — high priority

`lib/financial_engine/planning/default_financial_planner.dart` still emits the literal `idempotencyKey: 'temporary'` in multiple plan-building branches. Separately, `lib/services/transaction_application_service.dart` defaults several operations to a `DateTime.now().millisecondsSinceEpoch` key. The engine cache is checked with `ExecutionContext.idempotencyKey`, so the planner's `temporary` field should not be misrepresented as the sole cause of every duplicate risk; nevertheless, plan metadata remains inconsistent with the accepted requirement for a stable operation identity, and timestamp-generated request keys can change on retry. The application command must carry a stable logical-operation key across retries, and the durable key/outcome must be committed atomically with the financial effect.

### Financial truth and exact money

- `FinancialOperationEngine` and mutation handlers are present, and most transaction command flow is routed through the engine.
- There are still many direct Hive references across screens, controllers, projections, and services. A static scan found approximately **111 `Hive.box` references** in `lib`. These are migration/boundary cleanup targets; not every direct access is itself a financial write, but the storage cutover cannot be completed by changing bootstrap alone.
- Legacy financial models still use `double` (including the transaction model), and some projections convert through `Money.fromDouble`. ADR-034's `Money`/`Decimal`-authoritative goal is therefore not fully applied throughout the model and calculation surface.
- The active executor's registry uses a `MemoryJournalEntryRepository` for journal-entry mutations while other transaction/ledger paths use Hive-backed ports/projections. This needs an explicit decision about the authoritative persisted ledger/journal boundary before Drift schema freeze.
- Correction/deletion planner entry points exist in this ZIP (`_planCorrection` and `_planDeletion`); older reconciliation documents that say those exact planner entry points are still unimplemented are stale relative to this snapshot. That alone does not prove all related edit/delete flows pass end-to-end tests.

## Credit-card and financing findings

### Current behavior present in source

- `CreditCardCycleResolver` centralizes the date policy for charge close dates, next-month due dates, reporting month, and month-end clamping. A corresponding test file covers common boundary cases.
- `CreditCardExpenseProjectionService` delegates its ordinary-purchase date projection to the resolver.
- `CreditCardMonthlyDueProjectionCalculator` has reconciliation diagnostics and a cap against the current card outstanding, with tests for reconciliation and cap suppression.
- A credit-card payment operation and `CreditCardPaymentDomainGuard` exist in this snapshot, with pipeline tests for partial/full settlement and invalid/over-limit cases.
- Credit-card financing conversion and financing contracts/schedules/installments exist in the current source. The conversion logic still uses multiple Hive boxes and compensating recovery rather than a single real DB transaction.

### Risks / inconsistencies

1. **Duplicated statement-cycle math.** `CreditCardStatementDueCalculator` still implements its own close-date and payment-due-date helpers instead of using `CreditCardCycleResolver`. That is a risk of the two projections drifting. Consolidate after a complete-project test run rather than blindly refactoring in this archive-only environment.
2. **Terminated financing obligations can disappear from projections.** Both monthly due projection and statement due calculation exclude contracts marked `terminated`. ADR-061 says each remaining obligation must explicitly be classified as settled, waived, transferred, remain payable, or subject to settlement; nothing is implicitly forgiven. Until that policy is implemented and tested, excluding every terminated contract can understate existing obligations if unpaid installments remain.
3. **Release matrix is stale for card payment.** `docs/ADR-RELEASE-STATUS-MATRIX.md` dated 28 September says ADR-051 has no V1 payment operation and is deferred. The 16 October source contains `CreditCardPaymentOperation` and a domain guard/test pipeline. The matrix needs updating to the actual scope. Do not conflate credit-card account settlement with full financing installment-payment allocation: ADR-054/055 financing-allocation integration may still be deferred.
4. **ADR status lags implementation.** The card charge file `ADR-047-CREDIT-CARD-CHARGE-OPERATION.md` remains `Proposed → Implementation`, while the source has an active charge pipeline and domain guard. Update status only after reviewing required tests/evidence and obtaining the project's approval decision.
5. **SMS/IFUP is a proposal, not a runtime feature.** ADR-074 defines a review-confirm-save pipeline and a production-save gate, but the current `lib/` and `test/` source has no SMS/IFUP runtime implementation. It explicitly requires Drift, real atomic UnitOfWork, stable idempotency, and restart/retry/concurrency tests before production saving.

## ADR canonicalization recommendations

These are **proposed mapping decisions**, not file operations performed by this audit.

| ADR group | Recommendation | Reason / hold point |
|---|---|---|
| ADR-004 | Keep `docs/02-ADR/ADR-004 — Domain Mutation Execution.md` as the readable canonical content; archive the five byte-identical filename variants after checking all path references. | The six files have the same SHA-256. The title describes the accepted single-writer/engine execution boundary. The separate `ADR-004 - Financial Operation Execution Engine - Copy.md` in `docs/New folder/` is historical material and needs semantic reconciliation, not a second active number. |
| ADR-028 | Keep `docs/02-ADR/ADR-028 — Allocation Contract.md`; archive the five byte-identical variants after reference review. | Six copies have identical SHA-256. |
| ADR-046 | Keep `ADR-046-MONTHLY-DUE-DATE-ROLLOVER-POLICY.md` as ADR-046. | It is the accepted periodic/monthly rollover decision. |
| Scheduled execution atomicity/recovery | The file `ADR-047-SCHEDULED-EXECUTION-ATOMICITY-AND-RECOVERY.md` has internal title **ADR-046**, and an equivalent copy exists at `docs/ADR-046-SCHEDULED-EXECUTION-ATOMICITY-AND-RECOVERY.md`. Propose a new unused number (ADR-076 is available in this snapshot) only after owner approval and repository-wide ref migration. | Its meaning differs from the accepted due-date rollover ADR-046; do not overwrite or silently reuse ADR-046. |
| ADR-047 / ADR-048 | Use `ADR-047-CREDIT-CARD-CHARGE-OPERATION.md` as the working canonical file. Treat `ADR-048 — Credit Card Charge Operation.md` as a duplicate of ADR-047, not an independent ADR-048. | The two contain the same decision/title/status after normalizing line endings. The reference graph also maps the standard file to ADR-047. Check links before archiving the other path. |
| ADR-050 | `...-REVISED.md` is the stronger working candidate, but it remains Proposed. | It adds the statement/installment relationship and no-double-counting semantics linked to ADR-069. Compare fully, approve, and migrate links before archiving the older version. |
| ADR-052 | `...-REVISED.md` is the stronger working candidate, but it remains Proposed. | It clarifies canonical principal and contract schema and updates a charge-operation reference. Verify all call sites/model fields and approve before superseding the older file. |
| ADR-053 | The short `ADR-053-INTEREST-CALCULATION-AND-INSTALLMENT-ALLOCATION-MODEL.md` marked **Accepted** is the current policy authority. Consolidate needed implementation details from the two Proposed long versions into one reviewed revision; archive neither until merged. | Three files have different status/coverage. Do not choose the longest file as canonical by filename or size. |
| ADR-062 | The short `ADR-062-FINANCING-OVERPAYMENT-AND-EXCESS-PAYMENT.md` marked **Accepted** governs: financial payment must reject non-zero `unallocatedAmount`; do not create hidden credit/future principal state. | The longer Proposed version may provide context but must not override the Accepted rule. |
| ADR-007 / ADR-0012 | Resolve internal-title mismatch before ADR cleanup. | Filename `ADR-007 Financial Engine is the only writer of Financial Truth..md` has an internal title that says `ADR-0012`; there is also a different `ADR-0012 Financial Execution Plan Completeness.md`. Do not rename based on filename alone. |
| ADR-030 / ADR-031 | Resolve internal-title mismatch. | `ADR-30-Money Reservation Architecture.md` identifies itself internally as ADR-031. Verify the reference graph before renaming. |
| ADR-071 | Keep as unresolved naming cleanup. | `(1)` is the only ADR-071 filename found in `docs/02-ADR` in this snapshot, but the suffix alone does not prove whether a rename is safe. |
| ADR-041 through ADR-045 | Review identical copies under both `docs/` and `docs/02-ADR/`; keep archive/freeze-pack copies only if the repository intentionally preserves those historical snapshots. | Duplicate documents may be historical freeze material rather than active canonical ADRs. Path references must be checked first. |

### ADR status principles

- A filename containing `REVISED` is not proof of acceptance.
- An `Accepted` short policy remains the authority until a new revision is explicitly approved.
- A code implementation does not automatically change an ADR's status, and a `Proposed` ADR does not prove the code is absent. Record both design status and runtime status separately.
- The current `ADR-INDEX.md` explicitly labels itself an **audit draft**, generated from the 13 October snapshot. It must not be treated as the final canonical ADR map.

## Other audit findings

- `docs/02-ARCHITECTURE_RECONCILIATION_V1.md` is itself partially stale: it says the planner's correction/deletion methods are unimplemented, while these methods are present in the reviewed 16 October source. Refresh reconciliation against this snapshot before using it to direct implementation work.
- `docs/ADR-RELEASE-STATUS-MATRIX.md`, `docs/FINAL_RELEASE_GATE_V1.md`, and release notes dated 28 September contain historical test/readiness claims. They are **not evidence that the modified 16 October source passed tests**.
- `docs/implementation/HIVE_TO_DRIFT_MIGRATION_INVENTORY.md` says its snapshot did not include `pubspec.yaml`; the 16 October ZIP does include it. Update the inventory using the complete 16 October source, including actual dependency manifest and current production wiring.
- The migration inventory notes an `Account` adapter Type ID conflict and some generated adapters absent from bootstrap registration. Re-check them directly against the complete working tree before Drift schema freeze; do not use Hive adapter Type IDs as SQL table IDs.
- Empty source/document files and corrupted-name copies exist in the archive. Treat them as cleanup candidates, not safe-to-delete files, until baseline and references are secured.

## Verification limitations

This was a static source and document audit. I did **not** run `flutter test`, `flutter analyze`, code generation, or a Flutter build because:

- Flutter/Dart SDKs are not installed in the audit environment.
- The ZIP omits `.git`, `pubspec.lock`, `assets/`, platform directories such as `android/`/`ios/`, and `analysis_options.yaml`.
- Several asset paths declared in `pubspec.yaml` are therefore absent from this archive.
- `Wafferly_Project_Rules.md` and `AGENTS.md` are absent from the 16 October ZIP, so their current working-tree versions cannot be confirmed from this archive.

The static inspection found 600 `.dart` files under `lib/` and 90 `.dart` test files under `test/`. This count is not a test result.

## Recommended sequence

1. **Secure the actual working-tree baseline**: retain the existing modified files, record `git status --short` and `git rev-parse HEAD`, then create a reviewed commit or backup before cleanup. Do not use `git clean`, broad reset, or the earlier Phase D canonicalization script.
2. **Approve architecture truth in writing**: mark current runtime = Hive; target runtime = Drift local-first optional cloud sync; ADR-075 remains Proposed until approved and implemented.
3. **Fix ADR number collisions**: ADR-004/028 duplicate names; ADR-046/047/048 scheduled-vs-card collision; ADR-007/0012 and ADR-030/031 title mismatch. Prepare a path migration map before moving files.
4. **Update runtime-status docs**: reconcile ADR-051 card payment status, ADR-047 charge status, current correction/deletion status, and the outdated release matrix.
5. **Treat Drift cutover as a separate implementation milestone**: refresh storage inventory from the complete project; decide persistent journal/ledger boundary; implement Drift repositories and real transactional UnitOfWork; stabilize operation identity/idempotency; replace direct Hive paths; test crash/retry/concurrency/reopen behavior.
6. **Only then** archive duplicate ADR copies, update every reference, run formatting/reference checks, `flutter analyze`, and full tests from the complete local project.

## Final verdict

The project is **not yet running on the intended Drift architecture**. The latest reviewed runtime remains Hive-based. The architectural destination is local-first Drift with optional cloud synchronization, but it must remain labeled **target / Proposed** until implemented, tested, and formally accepted. The most urgent work is not renaming files: it is ensuring durable, atomic financial writes and stable idempotency, then synchronizing the ADR/reference map to the actual code without losing the current uncommitted work.
