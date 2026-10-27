# ADR-080 — Installment Purchase Group and Atomic Creation

**Status:** Accepted — implementation deferred until the SQLite + Drift cutover is completed and its acceptance gates pass  
**Date:** 2026-10-27  
**Decision Type:** Credit Card Installment Purchase Modeling, Shared Metadata, and Atomic Financial Creation  
**Related:** ADR-034 (Exact Money Representation), ADR-052 (Installment / Financing Contract Model), ADR-059 (Financing Contract Replacement Policy), ADR-067 (Financing Operation Idempotency), ADR-068 (Financing Audit / Traceability Boundary), ADR-069 (Credit Card Statement ↔ Installment Relationship), ADR-070 (Credit Card Financing Conversion Boundary), ADR-075 (Hive to SQLite + Drift Cutover), ADR-076 (Scheduled Execution Atomicity and Recovery), ADR-077 (Credit Card Installment Down Payment Policy), ADR-078 (Credit Card Entry Mode Controls), ADR-079 (Credit Card Installment Effective-Date Semantics)

## 1. Context

An installment purchase may contain more than one financial component. For example, a purchase may have a down payment paid from a cash account and a financed principal charged to a Credit Card. These components describe one commercial purchase, but they are distinct financial events because they can have different source accounts, amounts, transaction types, and financial effects.

Treating the purchase as one financial transaction would erase that distinction and could produce incorrect account balances. Keeping two independent transactions without a durable shared purchase identity, however, makes shared metadata difficult to maintain consistently and makes the relationship unclear in transaction lists and detail screens.

The original purchase total must also be a durable value. It must not exist only as a temporary calculation performed during entry, because purchase details and financing-edit screens need to distinguish the original purchase price from the financed principal and from the total amount payable after interest and fees.

Finally, creating the purchase can require several related writes: the purchase group, the down-payment financial operation when applicable, the financed Credit Card charge, the financing contract, and the installment schedule and relationships. These writes must not leave a partially created authoritative financial operation if a later step fails.

The application is planned to replace Hive with SQLite through Drift under ADR-075. This decision must therefore target the Drift persistence architecture rather than add a temporary Hive implementation that would need to be redesigned during the cutover.

The owner has confirmed that Wafferly currently has no external users. Under the pre-release clean-cutover strategy in ADR-075, the existing Hive records are development/test data and are not treated as customer data requiring a general migration. This ADR therefore does not require automatic matching or retroactive grouping of legacy down-payment and financed-charge transactions.

## 2. Decision

### 2.1 Represent the commercial purchase with a dedicated `PurchaseGroup`

Create a durable `PurchaseGroup` record for an installment purchase created as one purchase flow. It is a commercial grouping and shared-metadata record; it is **not** a financial transaction, ledger entry, balance source, liability, or payment.

The group is the single source of truth for shared purchase metadata, including at minimum:

- stable group ID;
- original purchase total and purchase currency;
- main category and optional subcategory;
- merchant and/or purchase description, where supplied;
- purchase date;
- notes;
- creation and update timestamps, where required by the persistence conventions.

The final Drift schema may normalize merchant or description fields according to existing domain conventions, but it must not create multiple competing authoritative copies of the same shared metadata.

### 2.2 Keep the financial components independent

The down payment and financed Credit Card principal remain separate financial transactions/operations. Each component retains its own financial identity and all component-specific facts, including its source account, amount, currency representation, transaction type, status, and effective financial date under the existing financial-operation rules.

Each component must have a durable relationship to the `PurchaseGroup`, using an indexed foreign-key relationship or an equivalent constrained relation in the Drift schema. The relationship must identify the component's role, such as `down_payment` or `financed_charge`, either through an explicit role field or a normalized component relation. The schema must prevent more than one active component of a role where the domain permits only one.

A down payment is optional when the purchase flow allows it. A financed charge is required for this specific financed-purchase flow. Eligibility and source-account restrictions for the down payment remain governed by ADR-077; this ADR does not relax them.

### 2.3 Preserve the original purchase total

`PurchaseGroup.totalAmount` stores the original purchase price in the purchase currency. It is not the sum of all scheduled repayments, and it must not silently include future interest, financing fees, or other future costs.

Where a down payment is present and the down payment and financed principal are expressed in the same purchase currency, the invariant is:

```text
purchase total
    = down-payment amount
    + financed principal
```

For multi-currency cases, the system must compare component values in the group's purchase currency using explicit, persisted currency-conversion values/rates under ADR-034 and the existing money model. It must never add unlike currency values directly or silently introduce rounding or a currency reinterpretation.

Creation must reject or explicitly resolve an inconsistent total rather than save a group whose component amounts do not reconcile with the original purchase price.

### 2.4 Make the group authoritative for shared metadata

For transactions linked to a `PurchaseGroup`, the group is authoritative for shared purchase description, merchant, category, subcategory, purchase date, and notes wherever those fields represent the purchase as a whole.

Screens, search, and reports that show the shared purchase metadata must resolve it from the group. Updating shared metadata through the group/detail flow must update the presentation of all linked components without independently editing duplicated copies on each transaction.

Each transaction's financial date and immutable financial history remain governed by the financial-operation rules. A change to the group's purchase date changes the shared purchase metadata; it must not silently rewrite a posted transaction's effective date, a closed statement, or the historical financial effect. If the product needs a financial-date correction, it must use the relevant correction/reversal/replacement operation.

The UI must not make these two date meanings appear interchangeable. When the purchase date differs from a component's financial transaction date, the relevant details view must label them separately (for example, **Purchase date** and **Financial transaction date**) and explain that editing the purchase date does not change the posted financial date. The group editor must not imply that the underlying charge or payment was financially posted on the new purchase date.

For transactions not associated with a `PurchaseGroup`, existing transaction-level metadata semantics remain unchanged.

### 2.5 Preserve the financing-contract boundary

The financed Credit Card charge remains the originating financial event for its financing contract under ADR-070. `PurchaseGroup` supplements that relationship; it does not replace `originReference`, change the authority of the original charge, or create a second principal liability.

The contract and its schedule remain contractual/planning state according to ADR-052. Statement contributions remain a presentation/eligibility relationship under ADR-069 and must not be materialized as a duplicate financial transaction or liability.

### 2.6 Create the group and its required components atomically in Drift

After the Drift cutover defined by ADR-075, creation of a financed purchase must be orchestrated as one logical application operation and persisted within one real SQLite/Drift database transaction. The atomic boundary must include all required local authoritative writes for the selected operation, as applicable:

1. `PurchaseGroup` and its component relationships;
2. down-payment financial effect, when applicable, through the Financial Operation Engine;
3. financed Credit Card charge through the Financial Operation Engine;
4. financing contract and installment schedule through the financing-domain service;
5. required local statement/installment relationships and traceability records;
6. the durable idempotency outcome required by ADR-067.

All participating repositories/services must use the same transaction context/connection or transaction-aware unit of work. Merely calling several services sequentially, each of which opens and commits its own transaction, does not satisfy this decision.

The Financial Operation Engine remains the only writer of authoritative financial truth. The financing service must respect the writer boundary in ADR-070. The application orchestrator coordinates the operation; it must not bypass either domain boundary to write financial records directly.

External side effects such as cloud sync, analytics, notifications, or network calls must not run as unrepeatable work inside the database transaction. Any required post-commit delivery must use the existing post-commit/outbox conventions or a separately approved recovery design.

### 2.7 Use durable operation identity and idempotency

The logical create-purchase operation must have a stable identity that survives controller disposal, app restart, and retry. It must not rely solely on an in-memory `workflowId` or generate a new identity for every retry.

The operation must follow the durable idempotency and recovery mechanisms defined by ADR-067 and ADR-076. The same logical request retried after an interrupted response must return or recover the original outcome and must not create a second group, down payment, financed charge, financing contract, or installment schedule.

The implementation must not introduce a parallel retry/idempotency framework if the existing operation and recovery architecture can support this operation. Any persistent operation-intent record required to recover the same identity must be classified as operational metadata, not as an additional financial effect.

### 2.8 Legacy development data and clean cutover

At the Hive-to-Drift cutover, the app starts with a clean Drift database in accordance with ADR-075. Existing Hive test transactions without a `PurchaseGroup` are not automatically matched, rewritten, or assigned synthetic groups. No heuristic matching by amount, date, category, description, or account is permitted as part of this feature.

If the owner explicitly needs particular development records, preserving them is a separate developer-only export/archive or manually prepared fixture decision. Such preservation must not introduce a production runtime migration, dual-write, Hive fallback, or a second source of truth. The normal application startup and the purchase-group feature do not import old Hive records.

## 3. Editing and Cancellation Boundaries

- Shared metadata is edited through the `PurchaseGroup` detail/edit flow.
- A component's source account and other component-specific financial facts remain independent; changes must use the applicable financial operation or correction path rather than mutate posted financial truth directly.
- Amount, currency, or financing-term changes must not be available through a single component's ordinary edit screen. They require a unified purchase/financing workflow with validation of the group total and component amounts.
- If any installment has been paid, the system must preserve settled history and apply the applicable correction, reversal, cancellation, or contract-replacement policy. Directly editing or deleting the historical financed charge or settled payment is prohibited. ADR-059 and the relevant payment/settlement ADRs continue to govern those financial effects.
- Group cancellation/deletion must not cascade-delete posted transactions, settled payments, or historical financing records. It must invoke the appropriate financial lifecycle operation and retain the audit trail.

This ADR establishes the boundaries above; it does not create a new universal policy for early repayment, refund, contract termination, payment allocation, or replacement. Those remain governed by their existing ADRs.

## 4. Invariants

```text
One commercial purchase
    → one PurchaseGroup
```

```text
Down payment
    ≠
Financed Credit Card charge
```

```text
PurchaseGroup
    ≠
Financial transaction / ledger entry / balance mutation
```

```text
Purchase total
    =
Down payment + financed principal
```

subject to the same-purchase-currency reconciliation rule in Section 2.3.

```text
Financing contract
    ≠
Second principal liability
```

```text
Shared purchase metadata
    →
PurchaseGroup is the authoritative source
```

```text
Create purchase operation
    →
all required local authoritative writes commit together or none do
```

```text
Retry of the same logical operation
    →
at most one financial effect and one financing plan
```

## 5. Required Acceptance Tests

### Purchase grouping and metadata

- A purchase without a down payment creates one group, one financed charge, one financing contract, and one schedule.
- A purchase with a down payment creates one group and the two required independent financial components, with the expected roles and references.
- Both linked components display the same group-level merchant, description, category, subcategory, purchase date, and notes.
- Updating shared metadata through the group is reflected consistently in every linked component, list, search result, and applicable report.
- When `PurchaseGroup.purchaseDate` differs from a component's financial transaction date, the UI labels both dates distinctly and explains their different meanings.
- Editing the group purchase date does not rewrite a posted transaction's effective date or any closed statement.
- Non-group transactions retain their existing metadata behavior.

### Amount and currency reconciliation

- `totalAmount = down payment + financed principal` is validated for same-currency purchases.
- The optional-down-payment case validates `totalAmount = financed principal` when that is the supported flow.
- Invalid or inconsistent totals are rejected before commit.
- Mixed-currency values are never added directly; any supported conversion uses explicit currency and conversion data consistent with ADR-034.
- Interest and future financing fees do not get added to the original purchase total merely because they appear in the repayment schedule.

### Atomicity and idempotency

- Failure injected after each individual write leaves no partial authoritative purchase, financial effect, contract, or schedule.
- A failed down-payment or financed-charge operation rolls back all local writes in the logical operation.
- A failure while creating the contract or schedule rolls back the group and all financial effects in the same operation.
- Closing/killing the app before commit and retrying the same logical operation does not duplicate records.
- Closing/killing the app after commit but before the caller receives the result returns/reconciles the committed result without creating duplicates.
- Repeating the same operation identity concurrently creates at most one group, one set of financial components, one contract, and one schedule.
- Idempotency outcome and financial effects are consistent after restart.
- Cloud sync/network unavailability does not prevent the local operation from completing.
- The first implementation plan includes failure-injection, interrupted-process, restart/retry, post-commit lost-response, and concurrent-retry tests from the outset; these are release gates, not optional follow-up hardening.

### Financial boundaries and lifecycle

- The down payment and financed charge retain their independent source accounts and financial effects.
- The financed charge remains the contract's `originReference` under ADR-070.
- Creating the group does not alter account balances or create an extra ledger entry by itself.
- Statement presentation does not double-count the originating liability and installment contribution.
- Group metadata edits do not rewrite a posted transaction's financial date or a closed statement.
- Cancellation or deletion does not erase settled financial history.
- After one or more installments are settled, amount changes follow the approved correction/replacement policy and preserve payment history.

## 6. Implementation Sequencing

This decision does not authorize implementing `PurchaseGroup` on Hive, nor a temporary Hive-era UI or metadata patch solely for this feature. Because there are no external users and the intended cutover starts with a clean Drift database, the feature should be implemented once against its target persistence architecture rather than built twice.

Implementation is deferred until the SQLite + Drift cutover and the real Drift-backed atomic `UnitOfWork` under ADR-075 are implemented and pass their acceptance tests. The cutover must not automatically group or import existing Hive test transactions. At that point:

1. Reinspect the then-current source code and existing transaction/financing tables; do not rely on older controller snapshots.
2. Add the group schema and relationships to the Drift schema design before freezing the schema.
3. Route creation through one transaction-aware application operation, preserving the Financial Operation Engine and financing-service writer boundaries.
4. Design the failure-injection, interruption, restart/retry, idempotency, and concurrency tests together with the operation boundary; do not postpone them until after the feature is implemented.
5. Implement durable idempotency/recovery using ADR-067 and ADR-076.
6. Add and pass the acceptance tests in this ADR before enabling the flow.
7. Update `docs/02-ADR/ADR-INDEX.md` and any architecture/status records in the same documentation change.

If the Drift transaction context cannot span all required local writes without violating existing writer boundaries, stop and resolve the UnitOfWork/application-operation design before enabling this flow. Do not replace the atomicity requirement with sequential best-effort writes.

## 7. Out of Scope

- Changing the core balance engine or creating a second ledger.
- Replacing the Financial Operation Engine or bypassing its writer boundary.
- Changing financing interest calculations, installment allocation, statement eligibility, or payment rules.
- Defining a new universal refund, early-settlement, or contract-replacement policy.
- Implementing Hive dual-write, a temporary Hive `PurchaseGroup`, a temporary Hive-era UI/metadata implementation solely for this feature, or a Hive fallback after Drift cutover.
- Automatically matching, migrating, or synthesizing groups for existing Hive development/test transactions.
- Implementing cloud sync or an outbox beyond the existing approved architecture.

## 8. Consequences

### Positive

- The original purchase price is explicit and durable.
- Shared purchase metadata has one authoritative owner.
- The down payment and financed principal remain financially independent.
- The UI can show a purchase-level grouping without confusing it with an additional transaction.
- The atomic write boundary prevents partially created local financial state.
- Stable operation identity supports safe restart, retry, and duplicate prevention.
- The design fits the intended Drift cutover rather than requiring a temporary Hive implementation.

### Trade-offs

- Transaction lists, search, and reports must resolve group metadata for linked components.
- Drift schema, repository, and transaction-aware service interfaces must be designed to support the shared atomic boundary.
- Editing and cancellation become explicit group/financing workflows rather than ordinary single-transaction edits.
- More acceptance tests are required around failure injection, restart, retry, concurrency, and financial-history preservation.

**Implementation status:** Not implemented by this ADR. Acceptance of this decision is not evidence that the Drift schema, atomic UnitOfWork, repositories, or tests have been implemented or passed.
