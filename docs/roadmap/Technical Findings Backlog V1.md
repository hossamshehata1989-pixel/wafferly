Technical Findings Backlog V1

Status: Active
Purpose: Central register for technical, architectural, domain, and implementation findings discovered while executing the approved roadmap.

1. Purpose

This document prevents newly discovered issues from being forgotten without allowing every discovery to derail the current roadmap.

A finding is recorded first, then classified.

It is implemented immediately only when it blocks or belongs directly to the current Gate.

Otherwise, it remains in this backlog until its planned scope is reached.

Core rule

Discover → Record → Classify → Decide → Continue the Roadmap

A finding must not automatically become the next implementation task simply because it was discovered.

2. Finding Classification

Each finding must be placed into one of these states:

Open

The finding is confirmed and still requires investigation or a decision.

In Progress

The finding is currently being investigated or implemented as part of an approved scope.

Deferred

The finding is confirmed but does not block the current Gate and is intentionally postponed.

Closed

The finding has a documented decision and no further action is currently required.

Superseded

The finding was replaced by a later architectural decision or finding.

3. Gate Impact Rule

For every new finding, ask:

Does it block the current Gate?

If yes, investigate and resolve it before closing the Gate.

Is it directly part of the current Gate?

If yes, include it in the current scope.

Is it independent and safe to defer?

If yes, record it here and continue the roadmap.

Important

A finding must not expand the current Gate merely because it is technically interesting or related.

The current roadmap remains the execution authority.

4. Current Findings

ID

Finding

Status

Decision / Current Understanding

Target / Next Scope

F-001

Direct Balance Editing / Balance Adjustment

Closed

Direct balance editing is prohibited. Balance becomes read-only in Account Edit. Balance Reconciliation is the approved future Financial Operation for reconciling an observed balance difference.

Balance Reconciliation Accounting Contract

F-002

TransactionType.debt

Closed

Confirmed as dead legacy vocabulary with no current production/test usage found. Current debt financial movements use approved Financial Operation Engine flows. Physical removal is deferred pending persisted-data compatibility/cleanup policy.

Data cleanup / migration review

F-003

Financial Correction

Open

FinancialActionType.correction exists, but _planCorrection() remains unimplemented. Requires actual caller/semantics/accounting audit before implementation.

Current audit

F-004

Financial Deletion / Invalidation

Open

FinancialActionType.deletion exists, but _planDeletion() remains unimplemented. Requires domain decision and relationship to Correction/Invalidation.

After Correction audit

F-005

Legacy Allocation Store

Deferred

No active production write caller was established in the Single Writer audit. Equivalence with the PlanningEngine/HiveAllocationRepository path has not been formally proven; legacy readers remain.

Pre-Credit-Card / architecture cleanup

F-006

Legacy Reserved Money Store

Deferred

No active production write caller was established in the Single Writer audit. Legacy readers remain and must be reconciled with the current planning/projection model before removal.

Pre-Credit-Card / architecture cleanup

F-007

Balance Reconciliation Accounting Contract

Deferred

Domain concept approved, but debit/credit semantics, eligible account types, Journal contract, Net Worth impact, reasons, idempotency, and correction policy are not yet finalized.

Dedicated Balance Reconciliation design

F-008

Temporary Debt Settlement Operation

Deferred

Temporary Debt settlement is a distinct financial operation from generic Balance Adjustment/Reconciliation. A dedicated implementation was not found in the current code audit.

Debt implementation / financial integrity scope

5. Roadmap Discipline

The backlog does not replace the project roadmap.

The roadmap determines what is executed next.

This backlog answers a different question:

What did we discover that we must not forget?

Therefore:

Roadmap
   │
   ├── Current Gate
   │      │
   │      ├── Required finding → Resolve now
   │      │
   │      └── Independent finding → Record + Defer
   │
   └── Future Gates
          │
          └── Pull deferred findings when their scope is reached

6. Required Finding Workflow

For every newly discovered issue:

Step 1 — Record

Create a finding ID and write down the concrete evidence.

Step 2 — Verify

Confirm the finding against the actual repository/code/tests/docs.

Do not classify an issue as a real production problem based only on stale documentation or an unused symbol.

Step 3 — Classify

Determine whether it is:

Current Gate blocker

Current Gate scope

Future work

Documentation-only

Legacy/dead code

Non-production

Already resolved

Step 4 — Decision

If a domain or architectural decision is required, create/update the appropriate ADR or decision document.

Step 5 — Return to Roadmap

If the finding does not affect the current Gate, explicitly defer it and continue the planned roadmap.

7. What Must Not Happen

Do not create an implementation task for every discovery

A search result is not automatically a work item.

Do not create a new ADR for every finding

Use an ADR only when an architectural/domain decision is required.

Do not modify production code merely to make an audit look cleaner

Evidence comes first; implementation comes after a decision.

Do not close a finding because a test happens to pass

A passing test proves the tested behavior, not necessarily architectural completeness.

Do not mark a roadmap Gate complete while a confirmed blocker remains unresolved

The Gate remains open until its defined completion criteria are satisfied.

8. Relationship to ADRs

This backlog is the discovery and tracking layer.

ADRs remain the architectural decision layer.

Example:

Finding
  ↓
F-001 Direct Balance Editing
  ↓
ADR-036
  ↓
Decision:
Direct editing forbidden
Balance Reconciliation adopted

The backlog should reference the decision, while the ADR contains the full architectural reasoning.

9. Current Priority

The current roadmap focus remains:

Correction Audit
      ↓
Correction Decision / Implementation
      ↓
Deletion / Invalidation Audit
      ↓
Deletion Decision / Implementation
      ↓
Financial Integrity Verification
      ↓
Pre-Credit-Card Audit

The existence of deferred findings does not change this order unless a finding is proven to block the current Gate.

10. Completion Rule

A finding can be marked Closed only when:

The repository evidence has been reviewed.

The architectural/domain decision is known, where required.

Any required ADR/documentation has been updated.

Required implementation and tests are complete, if implementation was required.

No unresolved blocker remains for the finding.

11. Maintenance Rule

Update this document whenever a meaningful new finding is discovered.

Do not wait until the end of a Gate.

At the end of each Gate, review:

Open findings

Deferred findings

Findings closed during the Gate

Findings that became blockers

Findings whose target scope has now been reached

This keeps the backlog synchronized with the roadmap without allowing it to replace the roadmap.