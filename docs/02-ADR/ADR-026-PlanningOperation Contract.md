ADR-026 — PlanningOperation Contract

Status: Accepted

Date: 2026-08-05

Decision Type: Core Architecture

Scope: Planning Engine

1. Problem

The Planning domain requires a single immutable write primitive that represents every planning decision regardless of its source.

Without a canonical primitive:

Goals would reserve money differently from Budgets.
Commitments would implement their own reservation logic.
Manual reserve would become a separate implementation.
Automation, OCR, SMS and AI would all bypass planning rules.

This would duplicate business logic and eventually fragment the Planning Domain.

2. Decision

The Planning Engine adopts PlanningOperation as its only canonical write primitive.

Every planning decision enters the Planning Engine exclusively through a PlanningOperation.

No component may modify Allocation directly.

No domain may bypass the Planning Engine.

3. Responsibilities

PlanningOperation represents:

user intent
planning intent
execution request
immutable audit record

PlanningOperation does NOT represent current planning state.

Current planning state belongs to Allocation.

4. Immutable

PlanningOperation is immutable.

Once created it is never modified.

Correction is always performed by creating another PlanningOperation.

Examples:

Reserve

↓

Release

never

Update Reserve
5. Supported Operations

Initially the Planning Engine supports:

ReserveOperation

ReleaseOperation

ReallocateOperation

TransferToSavingOperation

Future operations may include:

SplitAllocationOperation

MergeAllocationOperation

PauseAllocationOperation

ResumeAllocationOperation

The engine must remain Open/Closed.

6. Operation Ownership

PlanningOperation belongs exclusively to Planning Engine.

Goals

Budgets

Commitments

Manual Reserve

Investments

Automation

AI

OCR

SMS

never manipulate Allocation directly.

They only request PlanningOperations.

7. Source Information

Every PlanningOperation must identify its origin.

Required fields:

sourceType

Goal

Budget

Commitment

ManualReserve

Investment

Automation

OCR

SMS

AI
sourceId
8. Actor Information

Every PlanningOperation must contain immutable actor information.

Required:

initiatedBy

Examples

User

Automation

AI

OCR

SMS

System

Future multi-user support depends on this field.

9. Execution Mode

Execution mode is independent from operation type.

Supported modes:

Immediate

Pending

Immediate

↓

execute now

Pending

↓

wait for user approval

Execution mode never changes planning meaning.

It only changes execution timing.


10. Execution Result

A PlanningOperation records:

- Requested Intent
- Final Outcome

Possible outcomes:

- Executed
- Rejected
- Cancelled
- Expired

Rejected operations remain part of the immutable audit trail.


② Generated Allocation IDs

Operations creating new Allocations
must persist generated Allocation IDs
inside the immutable operation record.

Generated identities are part of the historical record.


③ Metadata

Operation Metadata

Metadata never affects business rules.

Typical metadata:

reason

priority

tags

references

externalIds

debugInfo


④ Operation Version
schemaVersion