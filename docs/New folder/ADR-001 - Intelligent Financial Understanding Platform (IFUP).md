Status

Accepted

Context

Wafferly is designed to understand financial information originating from multiple heterogeneous sources.

Current and future supported sources include, but are not limited to:

Manual Entry
Voice Input
SMS Messages
OCR
Email
Bank APIs
Future Financial Integrations

Each source provides financial information in a different format, structure, and confidence level.

The platform requires a unified understanding layer capable of transforming any supported input into a normalized financial interpretation before any financial execution occurs.

Understanding financial information and executing financial operations are fundamentally different responsibilities and must remain architecturally independent.

Problem Statement

Without a dedicated understanding layer:

Every input source would require its own parsing logic.
Business rules would leak into parsing components.
AI integrations would become tightly coupled with financial execution.
Financial logic would gradually become dependent on specific input formats.
The platform would become increasingly difficult to extend and maintain.

The architecture therefore requires a dedicated interpretation platform that is completely independent from financial execution.

Decision

Introduce the Intelligent Financial Understanding Platform (IFUP) as a standalone architectural pillar.

The IFUP is solely responsible for understanding financial information regardless of its origin.

The Financial Operation Engine remains solely responsible for executing validated financial operations and producing Financial Truth.

Neither system may assume responsibilities belonging to the other.

Goals

The IFUP shall:

Understand financial intent.
Support multiple input sources.
Produce explainable results.
Minimize AI usage.
Learn over time.
Remain independent from financial execution.
Scale without architectural rewrites.
Non-Goals

The IFUP is NOT responsible for:

Executing transactions.
Updating balances.
Financial validation.
Ledger creation.
Double-entry accounting.
Account management.
Budget calculations.
Goal execution.

Those responsibilities belong exclusively to the Financial Operation Engine.

High-Level Architecture
                 Input Sources

     Manual
     Voice
     SMS
     OCR
     Email
     Bank APIs

            │
            ▼

──────────────────────────────────────────

Intelligent Financial Understanding Platform

──────────────────────────────────────────

Input Adapter

↓

Normalization

↓

Extractors

↓

Knowledge Gateway

↓

Confidence Aggregation

↓

Decision Engine
│

│── AI Service (Fallback Only)

↓

Understanding Result   
│
│── Canonical Financial Draft ────> Financial Operation Engine
│
│── Clarification Request ───────>  Presentation Layer


↓

Decision Trace accompanies every Understanding Result.

──────────────────────────────────────────

↓

Financial Operation Engine

↓

Financial Truth
Architectural Principles
1. Separation of Responsibilities

Understanding financial information is fundamentally different from executing financial operations.

The IFUP understands.

The Financial Operation Engine executes.

Financial Truth is produced only by the Financial Operation Engine.

2. Input Independence

No component inside the IFUP may depend on a specific input source.

Every source must be normalized before entering the understanding pipeline.

Adding new sources must not require changes to existing understanding logic.

3. Deterministic Before Probabilistic

The platform always prefers deterministic approaches whenever sufficient confidence can be achieved.

Examples include:

Rules
Dictionaries
Merchant Knowledge
Regex
Structured Extraction

Probabilistic techniques are introduced only when deterministic approaches cannot produce sufficient confidence.

4. AI is the Final Fallback

Artificial Intelligence is never the primary parser.

AI is consulted only after:

Extraction
Knowledge lookup
Confidence evaluation

have failed to reach the required confidence threshold.

This minimizes:

Cost
Latency
Vendor dependency

while maximizing explainability.

5. Explainability First

Every decision produced by the platform must be explainable.

The platform must always be capable of answering:

Why was this decision made?

Explainability is considered a core architectural requirement rather than a debugging feature.

6. Knowledge Driven Understanding

Financial understanding improves primarily through accumulated knowledge rather than increasing AI usage.

Knowledge is therefore treated as a first-class architectural component.

Core Pipeline

The IFUP processes every financial input through a fixed understanding pipeline.

Input

↓

Normalization

↓

Extractors

↓

Knowledge Gateway

↓

Confidence Aggregation

↓

Decision Engine

↓

AI Service (Optional)

↓

Decision Trace

↓

Understanding Result

Every input source follows the same pipeline regardless of origin.

Input Adapter

Input Adapters translate external sources into the platform's internal normalized input format.

Examples include:

Voice Adapter
SMS Adapter
OCR Adapter
Email Adapter
Bank Adapter

Adapters never perform financial understanding.

They only translate source-specific formats into the platform's canonical input representation.

Normalization

Normalization converts raw input into a standardized internal representation.

Examples include:

Number normalization
Currency normalization
Date normalization
Language normalization
Text cleanup
Unicode normalization

Normalization removes source-specific inconsistencies before extraction begins.

Extractor Architecture

Extractors are independent plugins responsible for identifying individual pieces of financial evidence.

Examples include:

Amount Extractor
Merchant Extractor
Category Extractor
Currency Extractor
Date Extractor
Person Extractor

Each extractor focuses on one responsibility only.

Extractors do not communicate with one another.

Extractors never call AI directly.

Extractors never access platform knowledge directly.

All knowledge interactions occur exclusively through the Knowledge Gateway.


Knowledge Gateway

The Knowledge Gateway is the single public entry point to all platform knowledge.

No component inside the IFUP is permitted to communicate directly with the underlying Knowledge Engine.

This architectural rule guarantees:

Consistent knowledge access
Centralized caching
Unified learning
Storage independence
Predictable behavior

The Knowledge Gateway abstracts all implementation details of knowledge storage.

Future storage technologies may change without affecting any extractor or understanding component.

Typical responsibilities include:

Query knowledge
Store knowledge
Update confidence
Strengthen knowledge
Weaken obsolete knowledge
Expire outdated knowledge

Every knowledge interaction passes through this gateway.

Knowledge Engine

The Knowledge Engine represents the platform's accumulated financial understanding.

It is responsible for maintaining all financial knowledge acquired by the system over time.

Knowledge is completely independent from individual extractors.

Extractors consume knowledge.

They never own knowledge.

Knowledge may originate from multiple scopes.

Global Knowledge

Knowledge shared by every user.

Examples include:

International merchants
Banks
Financial institutions
Public merchant categories
Common financial terminology
Personal Knowledge

Knowledge unique to an individual user.

Examples include:

Frequently visited merchants
User-specific nicknames
Preferred categories
Personal abbreviations
Local payment habits
Community Knowledge (Future)

Knowledge learned collectively from multiple users.

Community knowledge must always respect user privacy and data protection requirements.

This capability is intentionally deferred until future versions of the platform.

Knowledge Evolution

Knowledge is not permanent.

Every knowledge item evolves throughout its lifecycle.

Knowledge may:

Strengthen
Weaken
Expire
Be replaced
Become obsolete

Every knowledge item maintains metadata including:

Confidence
Creation date
Last usage
Usage count
Version
Source
Last update

Knowledge evolution allows the platform to continuously improve while preventing obsolete information from becoming permanent.

Confidence Aggregation

Each extractor produces evidence together with an associated confidence score.

The Confidence Aggregation layer combines all available evidence into a single confidence assessment.

The aggregation process must be:

Deterministic
Centralized
Explainable
Auditable
Side-effect free

Individual extractors are strictly prohibited from implementing their own confidence aggregation logic.

This guarantees that identical evidence always produces identical confidence results.

The exact aggregation algorithm is intentionally deferred and will be defined before implementation begins.

Decision Engine

The Decision Engine is responsible for making the final interpretation decision.

It evaluates:

Extracted evidence
Knowledge results
Aggregated confidence

The Decision Engine determines whether:

The current confidence is sufficient.
Additional clarification is required.
Artificial Intelligence should be consulted.
The platform cannot safely determine user intent.

The Decision Engine never performs extraction.

The Decision Engine never executes financial operations.

Its only responsibility is selecting the safest interpretation strategy.

The Decision Engine produces an Understanding Result.

An Understanding Result may be either:

Canonical Financial Draft
Clarification Request
Clarification Requests

Not every financial input should immediately produce a Financial Draft.

When confidence is insufficient but additional user input can reasonably resolve ambiguity, the platform generates a Clarification Request instead of making assumptions.

Examples include:

Unknown merchant
Multiple possible categories
Ambiguous account selection
Missing transaction date

Clarification Requests reduce AI usage while improving long-term platform knowledge.

User clarification is considered a valuable source of future learning.

Clarification Requests are returned to the presentation layer.

They are never sent to the Financial Operation Engine.

AI Service

Artificial Intelligence is accessed exclusively through a dedicated AI Service abstraction.

The IFUP never depends on any specific AI provider.

Possible providers include:

OpenAI
Claude
Gemini
Local Models
Future Providers

Only the Decision Engine may invoke the AI Service.

No extractor or knowledge component may directly communicate with AI.

AI responses may be cached to reduce operational cost and latency.

The exact caching strategy remains implementation-specific and is outside the scope of this ADR.

Decision Trace

Every Understanding Result must include a complete Decision Trace.

Decision Trace exists to provide:

Explainability
Debugging
Auditing
User feedback
Future learning

The trace records:

Evidence produced by every extractor
Knowledge consulted
Confidence evaluation
Rejected alternatives
Whether AI was used
Final reasoning path

Decision Trace is considered a first-class architectural component.

It exists independently from logging and debugging systems.


Understanding Result

The Decision Engine always produces an Understanding Result.

An Understanding Result represents the outcome of the platform's understanding process.

The Decision Engine may produce one of two result types:

Canonical Financial Draft
Clarification Request

These result types are mutually exclusive.

Canonical Financial Draft

A Canonical Financial Draft represents a complete financial interpretation.

A Financial Draft is considered ready for financial execution.

It contains all information required by the Financial Operation Engine.

Only Financial Drafts are permitted to cross the architectural boundary into the Financial Operation Engine.

The structure of the Canonical Financial Draft is intentionally deferred to ADR-002.

Clarification Request

A Clarification Request represents an incomplete understanding that can be resolved through additional user input.

Rather than making unsafe assumptions, the platform requests the minimum additional information necessary to safely continue.

Typical clarification scenarios include:

Unknown account
Ambiguous category
Multiple possible merchants
Missing transaction date
Conflicting extracted evidence

Clarification Requests are returned to the presentation layer.

They are never sent to the Financial Operation Engine.

Every Clarification Request must preserve the existing understanding context and previously extracted evidence to avoid restarting the understanding process.

Once additional information is received, the understanding pipeline is executed again using both the previous evidence and the newly provided information.

User Feedback

User corrections are valuable knowledge signals.

Whenever a user corrects an interpretation, the correction should become available to the Knowledge Gateway.

The exact learning workflow is intentionally deferred to a future ADR.

This ADR only establishes the architectural boundary between user feedback and platform knowledge.

Financial Operation Engine Separation

The Financial Operation Engine is completely independent from the IFUP.

The Engine neither understands financial inputs nor performs extraction.

Likewise, the IFUP never executes financial operations.

Communication between both systems occurs exclusively through the Canonical Financial Draft.

No other Understanding Result may cross this boundary.

This separation guarantees:

Independent evolution
Independent testing
Clear architectural ownership
Minimal coupling
Future Reserved Concepts

The following concepts are intentionally reserved for future architectural decisions and are not introduced in this ADR:

Canonical Financial Draft structure
Knowledge schema
Confidence aggregation algorithm
AI caching strategy
Learning workflow
Context enrichment between extractors
Community knowledge
Interpretation policies
Understanding context model

Reserving these concepts prevents premature abstraction while documenting anticipated evolution.

Consequences
Benefits
Complete separation between understanding and execution
Source-independent architecture
AI remains an optional fallback
Explainable decision making
Extensible plugin architecture
Knowledge-first evolution
Strong architectural boundaries
Reduced long-term maintenance cost
Trade-offs
Increased architectural complexity
Additional infrastructure components
More ADRs required
Higher initial design effort

These trade-offs are accepted in exchange for long-term scalability and maintainability.

Decision Summary

The Wafferly architecture is built upon two independent architectural pillars.

The first pillar is the Intelligent Financial Understanding Platform (IFUP), responsible for understanding financial information.

The second pillar is the Financial Operation Engine, responsible for producing Financial Truth.

The IFUP transforms heterogeneous financial inputs into an Understanding Result.

When the result is a Canonical Financial Draft, it is passed to the Financial Operation Engine.

When the result is a Clarification Request, it is returned to the presentation layer to collect additional user input before the understanding process resumes.

The Financial Operation Engine transforms the Financial Draft into validated financial operations and Financial Truth.

Neither system may assume responsibilities belonging to the other.

This separation is considered a permanent architectural principle of Wafferly.

ADR Status

Status: Accepted

Version: 1.0 (Final)