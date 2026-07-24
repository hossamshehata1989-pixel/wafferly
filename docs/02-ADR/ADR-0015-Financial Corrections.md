ADR-0015 — Financial Corrections

Status: Accepted

Context

During the migration to the V4 Financial Engine, the system needed to support editing and deleting financial transactions.

Traditional CRUD semantics conflict with Wafferly's strategic architecture.

The strategic investigation concluded that Wafferly is organized around Financial Truth Assurance, whose responsibility is to establish, preserve, and correct accepted financial truth—not simply store transactions.

Therefore, edit and delete operations must be reinterpreted as financial corrections rather than database mutations.

Decision

The Financial Engine will never expose generic CRUD operations such as:

UpdateTransaction
DeleteTransaction

Instead, it will expose domain operations representing financial corrections.

Financial Corrections

The Financial Engine supports three financial operations:

Create Financial Truth

Correct Financial Truth

Invalidate Financial Truth
Create

Creates a new accepted financial fact.

Produces:

Journal Entries
Ledger Entries
Transaction Record
Correct

Represents a correction to previously accepted financial truth.

Examples:

amount changed
source account changed
destination account changed
currency changed
financial category changed

The correction strategy is determined by the Planner.

Typical implementation:

Reverse Previous Truth

↓

Create New Truth

The caller does not decide the strategy.

The Financial Engine does.

Invalidate

Represents that previously accepted financial truth is no longer valid.

This is not a database delete.

Possible implementations include:

Reverse
Cancellation
Archive

The chosen strategy is determined by Financial Policies.

Metadata Updates

Not every modification is a financial correction.

The following fields do not affect financial truth:

Note
Tags
Attachments
UI preferences
Other metadata

These updates bypass the Financial Engine.

They are handled by a dedicated Metadata/Application service.

No journal entries are produced.

Responsibilities

Financial Engine is responsible for:

Financial correctness
Financial history
Financial integrity
Ledger consistency
Balance correctness

Metadata services are responsible for:

Notes
Tags
UI information
Attachments
Consequences

The system no longer models financial changes as CRUD operations.

Instead, financial behavior is expressed using domain language centered around Financial Truth Assurance.

This keeps the Financial Engine aligned with Wafferly's Core Subdomain and preserves financial integrity over time.