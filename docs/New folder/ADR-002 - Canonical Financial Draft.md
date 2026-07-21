ADR-002 — Canonical Financial DraftStatus

Accepted

Context

The Intelligent Financial Understanding Platform (IFUP) is responsible for transforming heterogeneous financial inputs into a unified understanding of financial events.

Regardless of whether the input originates from manual entry, voice, OCR, SMS, email, bank integrations, or future input sources, the IFUP produces a standardized understanding result.

Whenever sufficient understanding has been achieved, the IFUP produces a Canonical Financial Draft.

The Financial Operation Engine consumes this Draft to produce Financial Truth.

The Canonical Financial Draft therefore represents the sole architectural contract between financial understanding and financial execution.

A formally defined Draft is essential to preserve the architectural independence between both systems while allowing both to evolve independently over time.

Problem Statement

Without a canonical representation between understanding and execution:

Every input source introduces its own data structure.The Financial Operation Engine becomes coupled to input-specific formats.Understanding logic leaks into execution.Execution rules leak into understanding.Future integrations require modifications inside the Engine.Architectural boundaries gradually disappear.

The architecture therefore requires a single canonical representation that every successful understanding process must produce before financial execution begins.

Decision

Introduce the Canonical Financial Draft as the exclusive architectural contract exchanged between the Intelligent Financial Understanding Platform and the Financial Operation Engine.

The Draft represents a complete financial understanding that is ready for financial execution.

No alternative understanding artifact may cross this architectural boundary.

Whenever complete understanding cannot be achieved, the IFUP shall produce a Clarification Request instead of an incomplete Draft.

Goals

The Canonical Financial Draft shall:

represent financial understanding in a canonical form.remain independent from every input source.prevent interpretation inside the Engine.establish a stable contract between understanding and execution.remain deterministic.remain immutable.remain extensible for future financial domains.support long-term architectural evolution without coupling.Non-Goals

The Canonical Financial Draft is not responsible for:

executing financial operations.generating Financial Truth.creating accounting journal entries.performing ledger posting.validating balances.enforcing business rules.applying domain policies.allocating funds.reserving money.generating projections.

Those responsibilities belong exclusively to the Financial Operation Engine.

Canonical Financial Draft Definition

A Canonical Financial Draft represents a complete interpretation of a single financial event produced by the Intelligent Financial Understanding Platform.

It contains every piece of information required by the Financial Operation Engine to execute the financial operation from an understanding perspective.

The Draft answers:

What happened?

The Financial Operation Engine answers:

How should it be recorded?

The Draft is independent from:

User InterfaceInput SourceAI ProviderKnowledge SystemStorage TechnologyAccounting Implementation

A single understanding process produces at most one Canonical Financial Draft.

A single input may initiate multiple independent understanding processes, each capable of producing its own Draft or Clarification Request.

Draft Design Principles

The Canonical Financial Draft follows the following architectural principles.

Value Object

The Draft represents a semantic financial event rather than an entity.

Its meaning is determined by its content rather than by runtime identity.

Value Object semantics define the Draft itself. Correlation, orchestration, and traceability belong to higher-level architectural components and are intentionally excluded from the Draft.

Immutable

Once produced, a Draft represents a historical understanding result.

It must never be modified.

Corrections require producing a new Draft rather than mutating an existing one.

Versionable

The Draft is designed to support schema evolution without breaking architectural compatibility.

The existence and implementation of version identifiers are intentionally deferred to future ADRs.

Self-Describing

A Draft must be understandable without requiring access to its originating input.

Every consumer should understand the financial event exclusively from the Draft itself.

Complete

The Draft contains every mandatory piece of information required for financial execution from an understanding perspective.

No mandatory understanding information may remain unresolved.

Extensible

The Draft must allow future financial domains to evolve without breaking existing architectural contracts.

Future financial concepts may extend the Draft while preserving backward compatibility.

Architectural PrinciplesCanonical Representation

Every successful understanding process produces the same canonical representation regardless of the original input source.

Voice, OCR, SMS, Email, Manual Entry, APIs, and future integrations all converge into the same Draft model.

Source Independence

The Draft carries no assumptions about how understanding was achieved.

The Financial Operation Engine must never determine whether a Draft originated from AI, OCR, Voice Recognition, Manual Entry, or any future technology.

Complete Before Execution

A Draft must be complete before it is allowed to cross the architectural boundary.

Completeness refers to interpretive completeness, not accounting completeness.

The Draft completely explains the financial event.

The Financial Operation Engine determines how that event is represented inside the financial domain.

Engine Contract

The Financial Operation Engine assumes that every received Draft is complete from an understanding perspective.

The Engine never:

interpretsguessesinferscompletes missing understanding information

Its responsibility begins only after understanding has been completed.

Separation of Responsibilities

The IFUP understands financial events.

The Financial Operation Engine executes financial operations.

Neither system may assume responsibilities belonging to the other.

Draft Completeness

A Canonical Financial Draft is considered complete when no additional interpretation is required to understand the financial event.

Completeness is achieved only when every mandatory element necessary to describe the user's financial intent has been successfully identified.

Completeness does not imply that the financial operation will succeed.

A Draft may be completely understood while still being rejected during execution because of business or domain constraints.

The distinction between understanding completeness and execution validity is fundamental to the architecture.

Understanding Completeness

Understanding Completeness answers:

What happened?Who performed the action?Which financial accounts were referenced by the user?What monetary values were involved?When did the event occur?What financial category or purpose does the event represent?What additional contextual information is necessary to understand the event?

When these questions can be answered without ambiguity, the Draft is considered complete.

Accounting Completeness

Accounting Completeness belongs exclusively to the Financial Operation Engine.

It includes responsibilities such as:

Journal generationLedger mappingDouble-entry accountingPosting logicFinancial allocationsReservation logicProjection generation

These responsibilities are intentionally excluded from the Draft.

The Draft describes the financial event.

The Engine determines how that event becomes Financial Truth.

Draft Lifecycle

A Draft exists only after successful understanding.

Financial Input

↓

Understanding Pipeline

↓

Understanding Result

├── Canonical Financial Draft

└── Clarification Request

Only the Canonical Financial Draft may cross into the Financial Operation Engine.

Clarification Requests terminate the understanding process until additional user information becomes available.

Lifecycle Rules

A Draft:

is created exactly once.is never modified.is either executed or discarded.is never partially completed.never returns to the Understanding Pipeline after creation.

If new understanding becomes available, a completely new Draft is produced.

Required Understanding Information

Every Canonical Financial Draft contains all mandatory information required to uniquely describe a financial event.

Typical examples include:

Financial operation typeMonetary amountCurrencyEvent dateUser-referenced financial account(s)Financial categoryParticipants or members involvedMerchant or payee when applicable

The precise schema is intentionally deferred to future ADRs.

This ADR defines architectural responsibilities rather than structural implementation.

Optional Information

A Draft may include additional contextual information that improves understanding without changing the semantic meaning of the financial event.

Examples include:

NotesAttachmentsMerchant metadataGeographic informationExternal referencesImport metadata

Optional information must never redefine or alter the interpreted financial event.

Validation Boundary

The Intelligent Financial Understanding Platform validates understanding.

The Financial Operation Engine validates execution.

These responsibilities are intentionally separated.

IFUP Guarantees

Before producing a Draft, the IFUP guarantees:

Complete understanding.Consistent interpretation.No unresolved ambiguity.Deterministic understanding result.

The IFUP does not guarantee that financial execution will succeed.

Engine Responsibilities

The Financial Operation Engine validates:

Business rulesDomain rulesAccount existenceAccount stateBalance constraintsFinancial policiesBudget constraintsGoal constraintsPermission rulesFinancial integrity rules

The Engine may reject a perfectly understood Draft.

Such rejection represents business validation rather than failed understanding.

Engine Boundary

Communication between the Intelligent Financial Understanding Platform and the Financial Operation Engine occurs exclusively through the Canonical Financial Draft.

The Engine never consumes:

Raw user inputOCR outputSpeech recognition outputAI responsesExtractor resultsKnowledge entriesConfidence scoresClarification RequestsIntermediate understanding artifacts

Every execution begins with a Canonical Financial Draft.

No other understanding artifact may cross this architectural boundary.

Architectural Invariants

The following architectural rules are permanent and must never be violated.

Invariant 1

Incomplete Drafts never cross the Engine boundary.

Invariant 2

The Financial Operation Engine never interprets financial intent.

Invariant 3

The Intelligent Financial Understanding Platform never performs financial execution.

Invariant 4

The Draft answers what happened.

The Engine determines how it is recorded.

Invariant 5

Business validation must never be used to compensate for incomplete understanding.

Invariant 6

Clarification Requests replace incomplete Drafts.

They never coexist for the same understanding process.

Future Reserved Concepts

The following concepts are intentionally reserved for future ADRs.

Their existence is acknowledged, but their detailed design is deferred to preserve the scope of this ADR.

Future ADRs may define:

Complete Draft SchemaField DefinitionsSerialization StrategyVersioning StrategyMetadata ModelUnderstanding SessionCorrelation ArchitectureTraceability ArchitectureMulti-Currency ExtensionsInvestment ExtensionsLoan ExtensionsInstallment ExtensionsBudget ExtensionsGoal ExtensionsScheduled Action ExtensionsTax ExtensionsImport/Export Extensions

Understanding orchestration, traceability, and correlation are intentionally separated from the Canonical Financial Draft.

The Draft remains a pure business artifact that describes a financial event.

Higher-level architectural components are responsible for managing execution context, understanding sessions, traceability, and audit relationships.

The Canonical Financial Draft has been intentionally designed to support these future extensions without requiring changes to the architectural contract established by this ADR.

ConsequencesPositive Consequences

Adopting the Canonical Financial Draft provides several long-term architectural benefits.

Stable Architectural Boundary

Understanding and execution become fully decoupled.

Each system evolves independently while preserving a stable contract.

Input Source Independence

The Financial Operation Engine no longer depends on:

Manual EntryOCRVoice RecognitionSMS ParsingEmail ParsingAI ProvidersFuture Input Technologies

All integrations terminate at the Draft.

Clear Separation of Responsibilities

The IFUP becomes solely responsible for understanding.

The Financial Operation Engine becomes solely responsible for execution.

Architectural responsibilities never overlap.

Simplified Engine

The Engine never performs:

interpretationguessingintent recoveryambiguity resolution

Its implementation becomes deterministic and easier to reason about.

Easier Testing

Both systems can be tested independently.

The IFUP is validated by understanding quality.

The Engine is validated by execution correctness.

Neither system requires knowledge of the other's implementation.

Future Extensibility

New financial domains may extend the Draft without changing the architectural boundary.

New input sources require changes only inside the IFUP.

The Financial Operation Engine remains stable.

Context-Free Business Artifact

The Canonical Financial Draft remains independent from orchestration concerns such as:

Understanding SessionsCorrelation ModelsDecision Trace orchestrationAudit relationships

This separation preserves the Draft as a pure business representation while allowing orchestration architectures to evolve independently.

Trade-offs

The chosen architecture intentionally increases responsibility inside the Intelligent Financial Understanding Platform.

This includes:

richer understanding logicclarification workflowshigher preprocessing complexitymore sophisticated extraction pipelines

These trade-offs are accepted because they preserve a significantly simpler and more stable execution engine.

Architectural complexity is intentionally concentrated inside the understanding layer rather than distributed across the entire financial architecture.

Rejected AlternativesIntent-Based Draft

An alternative design considered representing only the user's financial intent.

Under that approach, the Financial Operation Engine would complete missing information and infer execution details.

This alternative was rejected because it introduces interpretation into the execution layer and weakens the architectural boundary established in ADR-001.

Source-Specific Drafts

Another alternative allowed each input source to generate its own Draft model.

This approach was rejected because it couples the Engine to input technologies and prevents long-term scalability.

Partial Drafts

Allowing partially understood Drafts to enter the Engine was also considered.

This approach was rejected because it transfers understanding responsibilities into the execution layer.

Incomplete understanding must instead produce a Clarification Request.

Context-Aware Draft

Another alternative considered embedding orchestration information such as session identifiers, correlation identifiers, or traceability metadata directly into the Canonical Financial Draft.

This alternative was rejected because orchestration context is not part of the financial event itself.

Embedding orchestration concerns into the Draft would weaken its Value Object semantics and couple a pure business artifact to workflow management responsibilities.

Traceability, correlation, and execution context belong to higher-level architectural components rather than to the Draft itself.

Relationship to ADR-001

This ADR operationalizes the architectural boundary introduced in ADR-001.

ADR-001 defines:

Who understands.

ADR-002 defines:

What crosses the boundary after understanding has completed.

Together they establish the complete separation between financial understanding and financial execution.

Decision Summary

The Canonical Financial Draft is the exclusive architectural contract exchanged between the Intelligent Financial Understanding Platform and the Financial Operation Engine.

It represents a complete financial understanding of a single financial event.

The Draft is:

canonicalimmutableself-describingcomplete from an understanding perspectiveindependent of input sourcecontext-freeextensible by design

The Draft answers:

What happened?

The Financial Operation Engine answers:

How should it be recorded and validated?

Understanding orchestration, correlation, traceability, and workflow management remain outside the Draft and belong to dedicated architectural components.

If complete understanding cannot be achieved, the IFUP produces a Clarification Request instead of a Draft.

Incomplete Drafts never cross the architectural boundary.

The Financial Operation Engine never interprets financial intent.

Together, these principles preserve a strict separation between understanding and execution, ensuring that both systems remain independently evolvable while sharing a stable, deterministic, and future-proof architectural contract.

Final Decision

Status: ✅ Accepted

Supersedes: None

Superseded By: None

Related ADRs:

ADR-001 — Intelligent Financial Understanding Platform (IFUP)ADR-003 — Canonical Financial Draft Schema (Planned)ADR-00X — Understanding Session & Correlation Architecture (Planned)