# ADR-003 — Understanding Workflow Model

**Status:** Accepted

---

# 1. Context

ADR-001 established the responsibility of the **Intelligent Financial Understanding Platform (IFUP)** as the architectural subsystem responsible for transforming arbitrary financial inputs into a canonical representation suitable for financial execution.

ADR-002 defined the **Canonical Financial Draft** as the only artifact allowed to cross the architectural boundary between IFUP and the Financial Operation Engine. It also established that the Draft is a context-free contract and must remain independent from the understanding workflow that produced it.

During the architectural design of the understanding subsystem, it became clear that the workflow naturally contains two distinct conceptual levels that must remain separate:

* The lifecycle of understanding an input occurrence.
* The individual understanding of each financial event contained within that input.

Separating these concerns creates clear architectural boundaries, improves scalability, enables batch processing, and preserves the isolation of the Financial Operation Engine.

---

# 2. Decision

The IFUP understanding workflow is modeled using four primary architectural concepts:

```text
Input Occurrence
        │
        ▼
Understanding Session
        │
        ├───────────────┐
        ▼               ▼
Understanding      Understanding
Process            Process
        │               │
        ▼               ▼
Understanding     Understanding
Result            Result
        │
        ▼
Canonical Financial Draft
```

Each concept has a distinct architectural responsibility.

---

# 3. Architectural Concepts

## 3.1 Input Occurrence

An **Input Occurrence** represents a single incoming unit received by IFUP.

Examples include:

* One SMS
* One OCR image
* One PDF
* One Email
* One Voice Recording
* One Imported Bank Statement
* One CSV Import

The Input Occurrence defines the outer boundary of one understanding attempt.

It contains no understanding logic and performs no interpretation.

Its sole responsibility is representing the original incoming financial input.

---

## 3.2 Understanding Session

An **Understanding Session** represents the complete understanding lifecycle initiated by exactly one Input Occurrence.

The Session is the architectural boundary for context, orchestration, lifecycle management, and correlation.

It does **not** perform financial understanding itself.

### Responsibilities

The Session is responsible for:

* Maintaining lifecycle state.
* Coordinating one or more Understanding Processes.
* Managing clarification suspension and resumption.
* Correlating all understanding activity originating from the same Input Occurrence.
* Providing the audit boundary for the complete understanding workflow.

The Session is **not** responsible for:

* Extracting information.
* AI reasoning.
* Knowledge retrieval.
* Producing financial drafts.
* Financial execution.

Those responsibilities belong to Understanding Processes and downstream components.

---

## 3.3 Understanding Process

An **Understanding Process** represents one independent unit of financial understanding within a Session.

Each Process attempts to understand exactly one candidate financial event.

Examples:

A single SMS may generate:

* Process #1 → Coffee purchase
* Process #2 → ATM withdrawal

A bank statement may generate dozens of independent Processes.

The Understanding Process is considered a **first-class architectural concept** because it defines its own responsibilities, invariants, lifecycle, and understanding artifacts.

This ADR intentionally does **not** prescribe whether the Process should be implemented as an Entity, Aggregate, Value Object, or any other DDD construct.

Implementation decisions remain outside the scope of this document.

### Responsibilities

A Process is responsible for:

* Understanding one financial event.
* Collecting event-specific evidence.
* Producing one Understanding Result.
* Maintaining the decision history for that understanding.
* Participating in clarification when necessary.

---

## 3.4 Understanding Result

Every Understanding Process may produce **exactly one** Understanding Result.

The only valid Understanding Results are:

* Canonical Financial Draft
* Clarification Request

These two outcomes are mutually exclusive.

A Process can never produce both.

Technical failures, user cancellation, expiration, or interruptions are **not** Understanding Results.

They are lifecycle outcomes of the Process itself and never modify the architectural contract established by ADR-002.

---

# 4. Understanding Session Lifecycle

The lifecycle of an Understanding Session is:

```text
Created

↓

Active

↓

Suspended (Clarification)

↓

Resumed

↓

Completed

or

Expired

or

Cancelled

or

Abandoned
```

Clarification never creates a new Session.

The Session remains alive throughout the clarification process.

### Completion Rule

A Session transitions to **Completed** only after **all** Understanding Processes have reached a terminal state.

Terminal states include:

* Completed
* Cancelled
* Failed

The Session acts as the orchestration boundary and therefore completes only when every Process has finished its own lifecycle.

---

# 5. Understanding Process Lifecycle

Each Process has an independent lifecycle inside the Session.

```text
Created

↓

Processing

↓

Clarifying

↓

Processing

↓

Completed

or

Cancelled

or

Failed
```

Multiple Processes may execute concurrently.

Each Process progresses independently from every other Process.

Completion of one Process never requires waiting for sibling Processes.

---

# 6. Correlation Model

The Understanding Session is the primary architectural correlation boundary.

Every understanding activity belongs to exactly one Session.

Within the Session, each artifact is additionally associated with the Understanding Process that produced it whenever applicable.

This architecture enables:

* Independent understanding
* Partial completion
* Batch processing
* Traceability
* Independent clarification
* Partial failures

without coupling unrelated financial events together.

---

# 7. Relationship Between Session and Process

One Input Occurrence creates exactly one Understanding Session.

One Understanding Session may contain one or many Understanding Processes.

Each Understanding Process belongs to exactly one Understanding Session.

A Process cannot exist outside its parent Session.

The Session coordinates the overall understanding workflow.

The Process performs the actual financial understanding.

These responsibilities are intentionally separated.

---

# 8. Relationship with the Canonical Financial Draft

The Canonical Financial Draft remains the only architectural contract between IFUP and the Financial Operation Engine.

Each Draft is produced by exactly one Understanding Process.

Once produced, a Draft may immediately cross the architectural boundary into the Financial Operation Engine without waiting for the completion of the remaining Processes in the same Session.

The Draft itself remains completely context-free.

It must never become coupled to:

* Session lifecycle
* Understanding workflow
* Clarification state
* Decision history
* AI reasoning
* Correlation metadata
* Orchestration metadata

This preserves the architectural boundary established by ADR-002.

---

# 9. Architectural Boundaries

The IFUP boundary ends when an Understanding Result is produced.

Only the Canonical Financial Draft may cross into the Financial Operation Engine.

The following concepts never cross that boundary:

* Understanding Session
* Understanding Process
* Evidence
* Decision History
* Clarification Context
* Confidence Evaluation
* AI Responses
* Internal Understanding Metadata

The Financial Operation Engine remains completely unaware of how understanding occurred.

---

# 10. Architectural Invariants

The following invariants are permanently enforced:

1. One Input Occurrence creates exactly one Understanding Session.
2. One Understanding Session may contain one or many Understanding Processes.
3. Each Process belongs to exactly one Session.
4. Each Process attempts to understand exactly one candidate financial event.
5. Each Process produces at most one Understanding Result.
6. The only valid Understanding Results are Canonical Financial Draft and Clarification Request.
7. Clarification never creates a new Session.
8. The Session remains alive during clarification.
9. A Session completes only after all Processes reach a terminal state.
10. A completed Process may immediately emit its Draft without waiting for sibling Processes.
11. The Canonical Financial Draft remains independent from the understanding workflow.
12. Only the Canonical Financial Draft crosses the IFUP boundary.
13. The Financial Operation Engine has no knowledge of Sessions, Processes, Evidence, Decision History, or orchestration.

---

# 11. Deferred Decisions

The following topics are intentionally outside the scope of ADR-003 and may be addressed by future ADRs:

* Decision Trace architecture
* Evidence architecture
* Learning Feedback architecture
* AI reasoning persistence
* Knowledge persistence
* DDD implementation model (Entity, Aggregate, Value Object)
* Persistence model
* Event sourcing strategy

---

# 12. Future Reserved Concepts

The architecture intentionally reserves the possibility of introducing additional orchestration concepts in the future without affecting the current workflow model.

Examples include:

* Understanding Thread
* Correlation Chain
* Cross-Session Understanding
* Long-running Financial Conversations

These concepts are intentionally deferred until justified by concrete business requirements.

---

# Final Decision

ADR-003 establishes the architectural workflow of financial understanding by separating four independent concepts:

* **Input Occurrence** — the incoming financial input.
* **Understanding Session** — the lifecycle, orchestration, and correlation boundary.
* **Understanding Process** — the architectural unit responsible for understanding a single financial event.
* **Understanding Result** — the outcome produced by each Process, consisting exclusively of either a Canonical Financial Draft or a Clarification Request.

This separation preserves the architectural independence of the Financial Operation Engine while enabling scalable support for bulk imports, multi-event inputs, clarification workflows, independent process execution, and future extensibility without introducing unnecessary coupling.
