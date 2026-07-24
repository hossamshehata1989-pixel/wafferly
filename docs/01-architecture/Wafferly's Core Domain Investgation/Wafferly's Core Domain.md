The Discovery of Wafferly's Core Domain
A Strategic Domain-Driven Design Investigation

Version: 1.0
Status: Official Architecture Paper
Project: Wafferly

Part I — Introduction
Background

Wafferly is a personal financial management platform designed to help individuals understand, manage, and improve their financial lives. While its visible features include recording income and expenses, managing accounts, planning budgets, tracking goals, and supporting future financial decisions, the architecture was intentionally designed to support a much broader financial ecosystem.

During the implementation of the Financial Engine, an apparently localized architectural problem emerged: how should financial edits and deletions be modeled without violating financial integrity?

What initially appeared to be an implementation detail gradually revealed a much deeper architectural question.

The investigation expanded beyond transaction editing, leading to increasingly fundamental questions:

What is the true architectural center of Wafferly?
Is Transaction the primary business concept?
Is Account the strategic heart of the system?
Does a higher-level business abstraction exist?
What responsibility is truly unique to a personal finance platform?

As the investigation progressed, many previously accepted assumptions were challenged. The search moved through multiple conceptual models—including Transaction, Financial Reality, Financial Truth, Financial Position, and irreducible business responsibilities—before ultimately shifting toward strategic domain analysis. This evolution is reflected throughout the investigation history recorded in the WASR documents.

Rather than searching for a better data model, the investigation became a strategic Domain-Driven Design exercise aimed at identifying the business responsibility that gives Wafferly its long-term architectural identity.

This document records that investigation from its original question to its final architectural conclusions. It documents not only the decisions that were made, but also the assumptions that were tested, the hypotheses that were rejected, and the reasoning that ultimately shaped the architecture.

Its purpose is to preserve the architectural rationale behind Wafferly's strategic design so that future evolution of the platform remains grounded in explicit decisions rather than implicit assumptions.

Document Scope

This document is not an ADR.

It is not a design specification.

It is not an implementation guide.

Instead, it is the official record of Wafferly's strategic architecture investigation. Its purpose is to explain why the architecture evolved the way it did, providing the reasoning behind the project's most important strategic decisions.

The implementation details are documented separately through ADRs, source code, and technical design documents. This paper focuses exclusively on the architectural discovery process and the strategic conclusions that emerged from it.


Part II — Investigation Timeline
Overview

The architectural investigation did not begin as an attempt to redesign Wafferly's domain model. It originated from a practical implementation challenge encountered during the evolution of the Financial Engine.

What initially appeared to be a localized technical question gradually exposed increasingly fundamental architectural uncertainties. Each answered question revealed a deeper one, ultimately transforming an implementation discussion into a strategic Domain-Driven Design investigation.

The following timeline summarizes the major stages of that journey.

Stage 1 — The Edit/Delete Problem

Starting Question

How should financial edits and deletions be implemented without violating financial integrity?

The investigation began while designing support for editing and deleting financial transactions. At that time, the existing Financial Engine supported only creation operations, making traditional CRUD-based approaches incompatible with the architectural principles already established. This led to the realization that the problem was not simply about implementing update operations, but about the language of the domain itself.

Key Outcome

The investigation shifted from implementation mechanics toward understanding the underlying business concepts responsible for financial change.

Stage 2 — Searching Beyond Transaction

The next hypothesis questioned whether Transaction truly represented the architectural center of the system.

Multiple alternative candidates were explored, including Accounts, Financial Reasoning, Financial Correction, Decision Layers, and higher-level abstractions above Transaction. Independent architectural reviews also challenged the assumption that Transaction should be treated as the starting point of a long-lived financial platform.

Key Outcome

The investigation concluded that Transaction alone could not explain the full business complexity of Wafferly.

Stage 3 — Financial Reality

The investigation then shifted toward understanding the business itself rather than its data structures.

New concepts emerged:

Financial Reality
Financial Truth
Financial Position

These concepts helped separate external business reality from the system's internal understanding of that reality. Rather than replacing existing architectural decisions, they provided a clearer conceptual framework for interpreting them.

Key Outcome

The investigation moved away from searching for a better entity and toward understanding business semantics.

Stage 4 — The Search for an Irreducible Responsibility

At this stage, the investigation abandoned the assumption that the architecture must revolve around a single business object.

Instead, it explored whether every essential concept within a personal finance platform emerged from one irreducible business responsibility.

Questions focused on identifying the responsibility that would remain even if planning, AI, goals, budgets, analytics, OCR, bank synchronization, and other optional capabilities were removed.

Key Outcome

The investigation shifted from objects toward responsibilities.

Stage 5 — Strategic Design

Further decomposition eventually reached diminishing returns.

Rather than continuing to search for increasingly abstract concepts, the investigation entered a Strategic Design phase focused on identifying Bounded Contexts, Context boundaries, Ubiquitous Languages, Aggregates, and relationships between domains.

Key Outcome

The investigation transitioned from conceptual exploration to strategic architectural modeling.

Stage 6 — Independent Validation and Final Distillation

The final stage combined:

internal architectural analysis,
multiple independent external reviews,
comparison of competing architectural interpretations,
and validation against Wafferly's long-term vision.

Rather than introducing new concepts, this stage evaluated the accumulated evidence to determine which architectural model most consistently explained the system as a whole.

This process ultimately produced the strategic conclusions documented in the remaining chapters of this paper.

Summary

The investigation evolved through six distinct stages:

Stage	Primary Question	Outcome
1	How should Edit/Delete work?	Revealed a deeper architectural problem
2	Is Transaction the architectural center?	Transaction rejected as the strategic starting point
3	What is Financial Reality?	Distinguished business reality from system understanding
4	What is the irreducible responsibility?	Shifted focus from objects to responsibilities
5	How should the domain be organized?	Transitioned to Strategic Design
6	Which model best explains Wafferly?	Final strategic architecture established


Part III — Searching for the Core Domain
The Original Assumption

Every long-lived software system appears to revolve around a central business concept.

For accounting systems, this concept is often assumed to be the Ledger.

For banking systems, it may be the Account.

For e-commerce platforms, the Order naturally occupies the architectural center.

When the investigation began, it was therefore considered reasonable to assume that Wafferly should also possess a single architectural center around which the rest of the domain could be organized.

The initial objective was simple:

Identify the Core Domain of Wafferly.

At this stage, the investigation implicitly assumed that the answer would be a business object.

That assumption would later prove to be incomplete.

The First Candidate — Transaction

Transaction was the most obvious starting point.

Nearly every visible feature of Wafferly appeared to revolve around transactions.

Users create expenses.

Users record income.

Transfers move money.

Balances change because of transactions.

Reports aggregate transactions.

The Financial Engine itself accepted financial operations that ultimately produced transactions.

From an implementation perspective, Transaction appeared to be the natural center of the system.

However, deeper analysis exposed several inconsistencies.

Transactions explain that something changed.

They do not explain:

whether the information is correct,
how conflicting information should be resolved,
how historical corrections should occur,
which information should ultimately become trusted financial knowledge.

As additional features were considered—including OCR, SMS parsing, bank synchronization, historical corrections, and reconciliation—it became increasingly clear that Transaction represents a recorded financial event rather than the business responsibility governing financial knowledge.

The investigation therefore concluded that Transaction could not adequately explain the strategic complexity of Wafferly. This direction had already begun to emerge in the architectural investigation, where Transaction was repeatedly questioned as the system's strategic starting point.

The Second Candidate — Account

The next candidate was Account.

Unlike Transaction, Accounts represented persistent financial state.

Balances originated from Accounts.

The architecture had already established Accounts as the Source of Truth for balances, making them one of the most stable concepts within the Financial Engine.

Nevertheless, Accounts exhibited a similar limitation.

Accounts answer questions such as:

How much money exists?
Where is it stored?
What is the current balance?

They do not determine:

whether incoming information is trustworthy,
how conflicting evidence should be resolved,
when financial history must be corrected,
how the system should preserve confidence over time.

Accounts represent financial state.

They do not govern financial truth.

Accordingly, Accounts remained a fundamental architectural building block without emerging as the Core Domain.

Beyond Business Objects

At this point the investigation reached an unexpected turning point.

Every candidate examined so far shared one characteristic:

Each was a business object.

Transaction.

Account.

Ledger.

Financial Position.

Financial Reality.

Each successfully modeled an aspect of the business.

None adequately explained the unique responsibility that distinguishes Wafferly as a personal finance platform.

The investigation therefore questioned one of its own foundational assumptions.

Perhaps the Core Domain was not an object at all.

Perhaps the search itself had been conducted at the wrong level of abstraction.

This realization fundamentally changed the direction of the investigation.

Instead of asking:

"What is the most important object?"

The investigation began asking:

"What is the most important responsibility?"

That shift became the defining transition of the entire architectural investigation.

Chapter Conclusion

The first phase of the investigation demonstrated that no existing business object could fully explain Wafferly's strategic complexity.

Rather than identifying a Core Entity, the investigation revealed that the search itself had been constrained by an incorrect assumption.

The next stage therefore abandoned object-centric thinking and began exploring whether Wafferly should instead be understood through its fundamental business responsibility.


Part IV — From Objects to Responsibilities
A Fundamental Shift

After examining Transaction, Account, Ledger, Financial Reality, and several higher-level abstractions, the investigation reached an unexpected conclusion.

The problem was no longer identifying a better business object.

The problem had become identifying the business responsibility that remains essential regardless of how the system evolves.

This marked the first major methodological shift of the investigation.

Instead of asking:

"What is Wafferly built around?"

the investigation began asking:

"What must Wafferly always do?"

This distinction appears subtle.

Architecturally, it changes everything.

Removing Everything Optional

To answer this new question, the investigation applied a reduction process.

Every optional capability was temporarily removed from the system.

Among the capabilities excluded from consideration were:

Artificial Intelligence
Planning
Goals
Budgets
Recommendations
Analytics
OCR
Bank Synchronization
Investments
Collaboration

The objective was straightforward.

If Wafferly were stripped down to its absolute minimum, what business responsibility would still remain?

This reduction became the central focus of the investigation.

Candidate Responsibilities

Several possible responsibilities were explored.

Could the system fundamentally exist to:

record financial events?
preserve financial history?
maintain balances?
account for money?
preserve financial state?
maintain financial knowledge?

Each candidate successfully explained part of the business.

None explained all of it.

Recording transactions, for example, does not explain reconciliation.

Maintaining balances does not explain conflicting information.

Accounting for money does not explain historical corrections.

Preserving history does not explain evolving confidence.

The investigation therefore concluded that each candidate represented an important responsibility, but not the complete architectural center.

A New Conceptual Framework

As object-centric thinking faded, another important realization emerged.

Several concepts that had previously been competing candidates were no longer competing.

Instead, they appeared to describe different aspects of the same business process.

Financial Reality represented the external world.

Financial Truth represented the system's accepted understanding of that world.

Financial Position represented the current financial state derived from that accepted understanding.

Rather than replacing one another, these concepts formed a coherent conceptual relationship that consistently appeared across multiple independent analyses.

This represented significant progress.

However, it still did not answer the central question.

The investigation had identified important concepts.

It had not yet identified the responsibility that produced them.

Recognizing a Limitation

At this stage, another important observation was made.

The investigation had become increasingly effective at decomposing concepts:

Financial Reality

↓

Financial Truth

↓

Financial Position

Yet every decomposition produced additional concepts rather than a definitive architectural answer.

The investigation therefore recognized diminishing returns.

Further conceptual decomposition alone was unlikely to reveal the Core Domain. This realization was formally recorded as a turning point toward Strategic Design.

Preparing for Strategic Design

Rather than continuing to invent new abstractions, the investigation changed direction once again.

Attention shifted toward:

Strategic Design
Bounded Contexts
Context relationships
Ubiquitous Language
Aggregate boundaries

The expectation was that the Core Domain might emerge naturally from understanding how the business is divided, rather than from continued conceptual abstraction.

Chapter Conclusion

This phase transformed the investigation in two important ways.

First, it demonstrated that the architecture could not be explained solely through business objects.

Second, it established that understanding Wafferly required reasoning about business responsibilities, conceptual relationships, and ultimately strategic boundaries.

The investigation had moved beyond implementation.

It had moved beyond entities.

It was now approaching the strategic structure of the business itself.


Part V — Strategic Distillation
A Change in Perspective

By this stage, the investigation had accumulated a large body of architectural observations.

Multiple concepts had been explored.

Multiple hypotheses had been proposed.

Several assumptions had already been rejected.

Yet an important question remained unanswered.

Which architectural model explains all observed behavior with the fewest assumptions?

Rather than generating additional concepts, the investigation entered a process of strategic distillation.

The objective was no longer to discover new ideas.

It was to identify which existing explanation consistently accounted for the architecture as a whole.

Independent Validation

One of the defining characteristics of the investigation was that its conclusions were not derived from a single line of reasoning.

Throughout the process, multiple independent architectural reviews were conducted.

Each review approached the problem from a different perspective, using different terminology and reasoning processes.

Although the reviewers frequently disagreed on names, classifications, and modeling approaches, a remarkable pattern emerged.

They consistently rejected the idea that Wafferly should be strategically organized around Transaction alone.

They also consistently distinguished between:

recording financial information,
understanding financial information,
maintaining financial consistency,
and planning future financial behavior.

The investigation therefore treated external reviews not as sources of authority, but as independent validation of emerging architectural patterns.

The Remaining Disagreement

By the end of the investigation, very few fundamental disagreements remained.

The most significant centered on the interpretation of the Ledger.

One interpretation viewed the Ledger as the complete accounting domain responsible for preserving financial correctness.

Another viewed the Ledger as the persistent record of financial facts, while the business responsibility for determining those facts belonged elsewhere.

This disagreement proved to be largely semantic rather than architectural.

Once the responsibilities of the Ledger were explicitly defined, the apparent disagreement largely disappeared.

The investigation therefore concluded that much of the remaining debate concerned terminology rather than system behavior.

The Critical Observation

As future capabilities were evaluated, another important realization emerged.

Wafferly was never intended to receive information from a single trusted source.

Its long-term architecture already anticipated multiple independent origins of financial knowledge, including:

manual user input,
OCR,
SMS parsing,
bank synchronization,
historical corrections,
reconciliation processes,
and future intelligent acquisition mechanisms.

These sources do not produce financial truth.

They produce financial claims.

Before any information becomes part of the system's official financial record, it must first be evaluated, validated, reconciled, and accepted.

This observation fundamentally distinguished Wafferly from systems whose primary responsibility begins only after financial facts are already known.

The Final Distillation

At this point, the investigation revisited every major candidate considered throughout the process.

Transaction explains financial events.

Accounts represent financial state.

Ledger preserves accepted financial facts.

Financial Position summarizes current standing.

Financial Reality represents the external world.

Each concept remained valid.

None required rejection.

Instead, a different pattern became visible.

Each concept represents either:

information,
state,
or persistence.

None represents the business responsibility that determines which financial knowledge ultimately becomes trusted by the system.

The investigation therefore identified a single responsibility that consistently explains every stage of the financial lifecycle.

That responsibility became the strategic center of the architecture.

Chapter Conclusion

The investigation did not discover a better entity.

It did not replace Transactions.

It did not replace Accounts.

It did not replace the Ledger.

Instead, it identified the responsibility that governs all of them.

The following chapter formally defines that responsibility and presents the final strategic architecture adopted for Wafferly.


Part VI — The Final Strategic Model
The Final Conclusion

After completing the investigation, evaluating multiple architectural hypotheses, conducting independent reviews, and validating the results against Wafferly's long-term vision, the investigation reached a single strategic conclusion.

The Core Subdomain of Wafferly is Financial Truth Assurance.

This conclusion was not reached by replacing existing concepts such as Transactions, Accounts, or the Ledger.

Instead, it emerged by identifying the business responsibility that explains why all of those concepts exist and how they interact throughout the financial lifecycle.

The investigation therefore concludes that Wafferly is strategically organized around the continuous production and preservation of trustworthy financial knowledge.

Definition

Financial Truth Assurance is the Core Subdomain responsible for continuously discovering, validating, reconciling, correcting, and preserving the system's accepted understanding of a user's financial reality over time.

Its responsibility is not to store financial information.

Its responsibility is to determine what should become accepted financial truth.

Once accepted, that truth becomes part of the platform's official financial record.

Relationship to the Ledger

One of the final architectural clarifications concerned the role of the Ledger.

The investigation concludes that the Ledger is not responsible for determining financial truth.

Instead, the Ledger is responsible for preserving financial facts that have already been accepted by the system.

This distinction separates two fundamentally different responsibilities.

The first is deciding what is true.

The second is recording what has already been accepted as true.

The architecture assigns the first responsibility to Financial Truth Assurance and the second to the Ledger.

Relationship to Transactions

Transactions remain essential.

However, they no longer occupy the strategic center of the architecture.

A Transaction represents a financial event.

It records the movement of money.

It explains how financial state changed.

It does not determine whether incoming information should be trusted, reconciled, corrected, or accepted.

Consequently, Transactions become one of the primary business artifacts governed by the Core Subdomain rather than the Core Subdomain itself.

Relationship to Accounts

Accounts continue to serve as the architectural Source of Truth for balances, a decision established earlier in the architecture and preserved throughout the investigation.

This decision is fully compatible with the strategic model.

Accounts answer questions about current financial state.

Financial Truth Assurance answers questions about financial correctness and acceptance.

The two responsibilities are complementary rather than competing.

Relationship to Financial Reality

Financial Reality remains an important business concept.

It represents the external financial world experienced by the user.

Financial Truth represents the system's currently accepted understanding of that world.

Financial Position represents the derived financial state based on that accepted understanding.

These concepts remain valuable because they describe different perspectives of the same business, not competing architectural centers. This conceptual relationship emerged during the investigation and remained consistently useful.

Why This Becomes the Core Subdomain

The investigation ultimately evaluated every candidate using the same criterion.

Can this concept explain the entire lifecycle of financial knowledge?

Financial Truth Assurance uniquely satisfies that criterion.

It governs:

acquisition of financial information,
validation,
reconciliation,
correction,
conflict resolution,
temporal consistency,
preservation of accepted truth,
and confidence in financial knowledge over time.

No other candidate consistently explained this complete lifecycle.

For that reason, it was selected as Wafferly's Core Subdomain.

Strategic Consequences

This conclusion has several architectural consequences.

The Financial Engine is no longer viewed merely as a transaction-processing pipeline.

Instead, it becomes one of the mechanisms through which Financial Truth Assurance fulfills its business responsibility.

Similarly:

Transactions become business artifacts.
Accounts represent financial state.
The Ledger persists accepted financial facts.
Future acquisition mechanisms (OCR, SMS, Bank Synchronization, AI-assisted import) provide financial claims that must be evaluated before becoming accepted truth.

Each component now occupies a clearly defined strategic role within a coherent business model.

Chapter Conclusion

The investigation did not identify a better data model.

It identified a better explanation of the business itself.

Financial Truth Assurance provides the organizing responsibility that connects financial acquisition, validation, correction, persistence, and historical consistency into a single strategic architecture.

It therefore becomes the Core Subdomain around which Wafferly's financial platform is designed.


Part VII — Conclusion
What This Investigation Achieved

The objective of this investigation was never to redesign Wafferly.

Its objective was to understand it.

What began as a discussion about implementing financial edits gradually evolved into a strategic examination of the architecture itself.

Along the way, numerous assumptions were questioned.

Some were confirmed.

Others were refined.

Several were abandoned entirely.

Rather than forcing the architecture to fit an existing conceptual model, the investigation allowed the business itself to determine the appropriate abstractions.

This approach required repeatedly challenging earlier conclusions, validating ideas through independent review, and favoring consistency over familiarity.

The resulting architecture therefore emerged through progressive refinement rather than initial design.

Final Strategic Understanding

The investigation concludes that Wafferly should not be understood primarily as a transaction recording system.

Nor should it be viewed simply as a ledger application.

Instead, Wafferly is a personal financial platform whose strategic complexity lies in continuously establishing and preserving trusted financial knowledge over time.

Within this model:

Transactions describe financial events.
Accounts represent financial state.
The Ledger preserves accepted financial facts.
Financial Truth Assurance governs the lifecycle through which financial information becomes accepted knowledge.

Each concept retains its own responsibility.

Together they form a coherent business model.

Architectural Implications

This conclusion provides a stable strategic foundation for future evolution.

New capabilities—including intelligent acquisition, OCR, bank synchronization, reconciliation, AI-assisted financial understanding, and future financial services—can now be introduced without redefining the architectural center of the platform.

The investigation therefore provides not only an explanation of the current architecture, but also a framework for evaluating future architectural decisions.

Future features should strengthen this model rather than bypass it.

Closing Statement

This document records the strategic reasoning that shaped Wafferly's architecture at this stage of its evolution.

It is not intended to prevent future change.

Architecture should continue to evolve as new business knowledge emerges.

However, future changes should be driven by demonstrated business requirements rather than unsupported assumptions.

The investigation documented here establishes the architectural baseline from which that future evolution can proceed.

Epilogue

Every software project eventually reaches a point where implementation must replace investigation.

For Wafferly, this document marks that point.

The strategic investigation is complete.

The architectural direction has been established.

From this point forward, the primary objective is no longer to discover the architecture.

It is to build it.