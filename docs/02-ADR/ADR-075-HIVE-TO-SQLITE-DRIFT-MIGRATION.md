# ADR-075 — Hive to SQLite + Drift Cutover (Pre-Release Clean Start)

**Status:** Proposed for final acceptance  
**Date:** 2026-10-13  
**Decision Type:** Local Persistence, Repository Cutover, and Atomic Financial Execution  
**Scope:** Replace the current Hive-backed implementation with SQLite through Drift before external testing and public release. No general-purpose migration of real customer data is planned for the current pre-release state.  
**Canonical location:** `docs/02-ADR/ADR-075-HIVE-TO-SQLITE-DRIFT-MIGRATION.md`

## Related Decisions and References

- `docs/01-FINANCIAL_FOUNDATION_FREEZE_V1.md` — financial truth boundaries, atomic execution, and idempotency gates.
- `docs/02-ARCHITECTURE_RECONCILIATION_V1.md` — accepted architecture versus actual implementation status.
- `docs/01-architecture/AI Architecture.md` — AI/IFUP boundary and local-first architecture reference.
- `docs/02-ADR/ADR-003-financial-operation-engine.md` — Financial Operation Engine boundary and executor responsibilities.
- `docs/02-ADR/ADR-004 — Domain Mutation Execution.md` — mutation execution and all-or-nothing behavior.
- `docs/02-ADR/ADR-007 Financial Engine is the only writer of Financial Truth..md` — single financial writer boundary.
- `docs/02-ADR/ADR-034-Exact-Money-Representation.md` — `Money`/`Decimal` is authoritative in the domain.
- `docs/02-ADR/ADR-047-SCHEDULED-EXECUTION-ATOMICITY-AND-RECOVERY.md` — current Hive multi-box atomicity limitation.
- `docs/02-ADR/ADR-067-FINANCING-OPERATION-IDEMPOTENCY.md` — stable operation identity and retry-safe effects.
- `docs/02-ADR/ADR-074-SMS-IFUP-V1-INTEGRATION.md` — SMS/IFUP production-save gate and draft persistence boundary.

> **Repository snapshot limitation:** The reviewed project archive did not include a complete Flutter project configuration, so current dependency resolution, all box registrations, and build/test execution were not verified. The complete current repository must be inspected for the inventory step below before schema implementation.

## 1. Context

Wafferly's accepted direction is local-first: SQLite through Drift is the sole local source of truth for financial data, with optional cloud sync independent from core financial operations and SMS processing.

The reviewed implementation still uses Hive in persistence paths and bootstraps a `MemoryFinancialUnitOfWork`, which does not supply real database transaction/rollback semantics. Hive boxes cannot participate in one relational SQLite transaction covering related financial changes and durable idempotency outcomes.

**Pre-release data assumption:** As of this decision, the owner confirms that no external users are using a distributed Wafferly build containing real financial data. Any existing Hive data is the owner's own development/test data. This makes a clean Drift start before friend testing and public launch safer and simpler than building a general-purpose customer migration system now.

If that assumption changes—for example, a build containing real user data is distributed before cutover—this ADR must be revisited before shipping an update. A dedicated data-preserving migration and recovery plan may then be required.

## 2. Decision

### 2.1 Target architecture

- SQLite, accessed through Drift, becomes the sole authoritative local persistence layer for financial and application state in scope.
- Existing domain contracts, the `FinancialOperationEngine`, and financial invariants remain authoritative. Drift is an infrastructure/persistence implementation, not a replacement financial engine.
- Repositories and ports should remain independent of Hive and Drift; storage-specific details belong in infrastructure adapters and database definitions.
- The Financial Engine remains the only writer of authoritative financial truth. UI, SMS, Voice, AI, parser, and migration/test helpers must not write financial records or balances directly.
- Cloud sync remains optional. No network connection is required to open the local database, understand messages locally, review a draft, or execute a supported local operation.

### 2.2 Clean cutover; no general customer-data migration in V1

Because no external users with real financial data exist at this stage, the default cutover strategy is:

1. Inventory the current Hive data model and actual persistence paths so the Drift schema covers the real entities, relationships, and invariants.
2. Build the Drift schema and repositories, then switch the development build to Drift as the sole active store before friend testing.
3. Start the new Drift database clean by default. Do not build a general-purpose Hive-to-Drift runtime migration runner, staged migration manifest, multi-phase production recovery protocol, or ongoing Hive/Drift dual-write solely to preserve the owner's disposable development/test data.
4. Remove Hive from active production read/write paths once Drift cutover and acceptance tests pass. Do not leave a silent Hive fallback.
5. If the owner wants to retain particular personal development data, a separate one-time developer-only export/import tool may be built. It is optional and must not be part of normal application startup or production user migration.

Before discarding the only copy of any owner-created test data that the owner chooses to retain, export it or keep a separate offline archive. Such an archive is a developer safety copy, not an operational fallback or a second source of truth.

### 2.3 Inventory is still mandatory

A clean start removes the need for a general-purpose migration engine; it does **not** remove the need to understand what the existing application persists. Before schema implementation, create a concise source-to-target inventory from the complete current repository covering:

- each registered Hive box, adapter/type ID, key format, persisted model, and box registration/opening path;
- accounts, transactions, corrections/invalidation, and any persisted ledger/journal records, distinguishing authoritative records from derived projections;
- credit-card profiles, linked accounts, financing contracts, installment schedules, payment/contribution records, and conversion events;
- planning allocations/reservations, goals/activity, scheduled rules/occurrences/execution state;
- idempotency results, operation traces/audit records, settings, and any other user-authored local data;
- data that exists only in memory and therefore is not persisted today.

For each entity, identify its future Drift table/repository owner, primary key, relationships, null/default rules, indexes/constraints, and how invariants will be tested. This list is an inventory checklist, not a claim that all listed records exist in the current implementation.

### 2.4 One authoritative store; no dual-write

- Before the development cutover, Hive is the current implementation's store.
- At cutover, the app switches to Drift and starts with a clean database by default.
- After cutover, Drift is the only authoritative local store; production code must not write to both Hive and Drift.
- Hive must not be used as an automatic runtime fallback after Drift has accepted writes. A stale Hive copy may not contain newer financial operations and cannot safely be treated as rollback truth.
- If a future release must preserve external users' Hive data, stop and create a separate migration decision before distributing that release. Do not improvise a data migration inside this clean-start ADR.

### 2.5 Real UnitOfWork and atomic execution

The production `UnitOfWork` must use real SQLite/Drift database transactions. A single logical financial operation either commits all required authoritative local effects or commits none of them.

As applicable to each operation contract, the atomic boundary includes:

- the canonical transaction/mutation record;
- authoritative ledger/journal changes;
- account, financing, schedule, or allocation state required by the operation;
- durable idempotency record and prior operation outcome;
- operation trace/audit data when the accepted contract requires atomic persistence.

The specific participants must be enumerated for each operation type during implementation. External work (network calls, analytics, AI calls, notifications, or cloud sync) must not run as an unrepeatable side effect inside the database transaction. Use post-commit processing or a durable outbox where delivery must be recoverable.

A database transaction does not replace Financial Engine validation, policy, planning, integrity, and idempotency checks.

### 2.6 Monetary representation compatibility

This cutover must comply with ADR-034 and must not silently combine a persistence replacement with a new financial arithmetic model.

- `Money` backed by `Decimal` remains authoritative in domain/business logic.
- No new financial domain arithmetic may use `double` as its authoritative representation.
- If current persistence uses legacy `double`, any optional one-time personal-data import must use explicit deterministic conversion and verify supported values without silent rounding, sign changes, or currency-scale reinterpretation.
- This ADR does not independently approve a new money encoding, rounding policy, or financial meaning.
- Currency, original/base amount, exchange rate, and precision semantics must remain unchanged. Invalid/non-finite legacy values must be surfaced, not silently corrected.

### 2.7 Stable idempotency and retry guarantees

- Replace production dependence on `MemoryFinancialUnitOfWork` with Drift-backed atomic execution before enabling financial production writes.
- Remove the temporary `idempotencyKey: 'temporary'` occurrences identified in the reviewed snapshot. Every retryable logical operation must use a stable operation identity that remains the same across retries.
- The durable idempotency outcome and financial effect must commit in the same transaction, or use a specifically designed recovery protocol with equivalent at-most-once guarantees.
- Repeating a logical operation after restart, process death, timeout, or concurrent confirmation must not create a second transaction, ledger movement, financing effect, or schedule transition.
- Since the default strategy starts the new Drift database clean, migration of old idempotency records is not required for this release. The optional personal-data importer, if created, must not claim to preserve idempotency behavior unless it explicitly imports and validates the related operation identities/outcomes.

### 2.8 Cloud-sync boundary

- Cloud sync is optional and cannot be required to finish a local financial operation.
- A committed local operation must remain correct with network access disabled.
- Any future sync queue/conflict metadata must stay outside the financial transaction boundary in a way that cannot create a second financial writer; recoverable delivery may use an outbox.
- SMS text, HMAC key material, and raw message fingerprints must not be sent to cloud sync. SMS/IFUP-specific privacy rules remain governed by ADR-074 and applicable platform/legal policy.

### 2.9 Security and local database protection

- The Drift database and its files must live in app-private storage. Financial values and draft data must not appear in logs, analytics, crash reports, or other diagnostic output.
- Drift/SQLite is not to be described as application-level encrypted merely because it is stored in the app-private sandbox.
- Before public release, explicitly decide and document at-rest encryption. The recommended default is a maintained encrypted-SQLite integration (for example SQLCipher compatibility) with key material protected by Android Keystore; do not implement custom encryption. If application-level encryption is not adopted, document the threat-model rationale and require explicit security acceptance before release.
- Database backups, if supported, must not contain exported Android Keystore key material. Backup/restore behavior must be consistent with the selected encryption strategy.

### 2.10 Scope of optional developer-data import

A one-time tool to import selected personal/test data is optional, not a prerequisite for the cutover. If requested by the owner:

1. Export only the selected development data explicitly.
2. Import through a developer-only command/tool into a disposable Drift database, not from normal application startup.
3. Compare record counts, stable IDs, account links, transaction totals, and relevant credit-card/financing relationships against the selected export.
4. Run the domain's invariant and balance checks, review differences, and only then decide whether that dataset is useful for testing.
5. Do not make the importer a general-purpose upgrade path or ship it to users.

If no historical personal/test data needs to be retained, skip the importer and use clean fixtures and test data created for Drift.

## 3. Consequences

### Positive

- Avoids building a high-complexity migration engine for external user data that does not currently exist.
- Enables SQLite/Drift before testing with friends, avoiding a second storage transition after real testers accumulate data.
- Provides a real transaction boundary for related financial effects and durable idempotency.
- Keeps one authoritative store and avoids split-brain risks from dual-writing Hive and Drift.
- Preserves the accepted money model and Financial Engine boundary.

### Costs and risks

- The owner's current Hive development/test data is not automatically retained. If needed, it requires an explicitly requested one-time export/import or must be recreated.
- Inventory and schema design still require careful review because many financial entity families may be involved.
- Cutover can expose existing implementation gaps; acceptance tests must pass before the Drift build becomes the baseline for friend testing.
- Encryption, backup behavior, and downgrade policy must be settled before public release.

## 4. Required Implementation Sequence

1. **Inventory:** inspect the complete current project and document Hive boxes/adapters, entities, repositories, open-box registrations, and current write/read paths.
2. **Schema design:** define Drift tables, constraints, indexes, DAOs/repositories, schema versioning, and ownership for each persisted entity.
3. **Financial execution:** implement the Drift-backed `UnitOfWork`, enumerate atomic participants for each operation, and ensure the Financial Engine uses a single database transaction context.
4. **Stable idempotency:** remove temporary keys and ensure operation outcome persistence commits atomically with financial effects.
5. **Repository cutover:** point the development build at Drift as the sole store, starting from a clean database; remove Hive from active production read/write paths. Do not dual-write.
6. **Optional personal-data path:** only if requested, create a one-time developer-only exporter/importer and validate imported data. This is not a release gate if the owner chooses a clean start.
7. **Acceptance tests:** pass financial invariants, atomicity, restart/retry/concurrency/idempotency, and offline tests before the build is used for the friends' test period.
8. **Security/release gates:** decide at-rest encryption, backup/restore behavior, and downgrade policy before public release. Ensure SMS/Voice production saves also satisfy ADR-074.

Work on SMS/IFUP parsing, provider templates, AI interfaces, and draft-only tests may proceed in parallel against test repositories/fixtures. Production saving from SMS/Voice stays blocked until ADR-074 and this ADR's atomic persistence/idempotency requirements are implemented and verified.

## 5. Acceptance Tests

### Clean cutover and persistence

- A fresh installation initializes Drift and works with an empty database.
- The app does not silently open an empty Drift database as if it had migrated prior Hive data; the pre-release cutover is explicitly configured as a clean start.
- After cutover, production repositories read/write Drift only; no dual-write or automatic Hive fallback remains.
- If the optional developer importer is implemented, repeated import attempts do not duplicate entities, and imported data passes the defined record/link/balance checks.

### Financial correctness and atomicity

- A mutation that fails after an earlier mutation is prepared leaves no partial authoritative state.
- Financial transaction and ledger effects commit together according to each operation contract.
- Idempotency outcomes survive restart and remain consistent with the related financial effect.
- Repeating the same operation key, concurrent confirmation, retry after process death, and retry after a committed operation create at most one financial effect.
- Offline local financial operations continue to work with cloud sync disabled/unavailable.
- Money values remain consistent with ADR-034 and do not silently round or change currency semantics.

### Security and release readiness

- Database content and developer diagnostics are inspected to ensure raw SMS, HMAC key material, and sensitive financial payloads are not leaked into logs or sync.
- The application-level database-encryption decision is recorded and implemented or explicitly accepted as an exception before public release.
- If an external build containing real user Hive data is ever distributed before cutover, this clean-start plan is not used to overwrite that data; a data-preserving migration ADR is required first.

## 6. Out of Scope

- A general-purpose migration runner for customers' Hive databases in the current pre-release state.
- Runtime dual-write or a Hive fallback after Drift cutover.
- Implementing SMS permissions, SMS listeners, provider parsers, or the AI provider itself.
- Implementing cloud sync or selecting its conflict-resolution protocol.
- Redesigning financial commands or changing supported financial operations.
- Changing financial money semantics or silently standardizing all legacy monetary values.

## 7. Open Decisions Before Implementation / Release

1. The complete current Hive inventory and canonical Drift table/repository mapping from the latest full project.
2. Whether the owner needs a one-time import of personal development/test data; default is clean start and skip importer.
3. The at-rest encryption approach and its Android Keystore/key-loss behavior; must be settled before public release.
4. Backup/restore policy for the Drift database, if database backup is enabled.
5. App downgrade policy once Drift has accepted writes; do not assume a Hive-only older version can safely reopen the app.
6. How any future distribution of a build containing real external user data changes this decision; create a dedicated migration ADR before such an upgrade if necessary.

## 8. Final Decision

This ADR proposes a pre-release clean cutover from Hive to SQLite/Drift, not a general-purpose customer-data migration. The current development build will use Drift as its sole authoritative local store before friend testing; existing personal/test Hive data is not imported by default. The complete Hive inventory, schema design, real Drift-backed atomic `UnitOfWork`, stable idempotency, financial invariants, and release security gates remain required. No dual-write or automatic Hive fallback is permitted. If real external user data appears before cutover, stop and replace this clean-start strategy with a dedicated data-preserving migration decision.

**Implementation status:** Not implemented by this document. Approval of the ADR is not evidence that Drift schema, repositories, encryption, or the Drift-backed `UnitOfWork` exist or pass tests.
