# ADR-074 — SMS and IFUP V1 Integration Architecture

**Status:** Proposed for final acceptance  
**Date:** 2026-10-13  
**Scope:** SMS understanding, shared financial understanding, local review, and integration with the Financial Operation Engine  
**Canonical location:** `docs/02-ADR/ADR-074-SMS-IFUP-V1-INTEGRATION.md`

## Related Project References

- `docs/01-architecture/AI Architecture.md` — canonical high-level AI/IFUP architecture reference (must be kept populated and consistent with this ADR).
- `docs/01-FINANCIAL_FOUNDATION_FREEZE_V1.md` — financial truth boundaries and implementation gates.
- `docs/02-ARCHITECTURE_RECONCILIATION_V1.md` — authority and reconciliation rules for project documentation.
- `docs/ADR-RELEASE-STATUS-MATRIX.md` — implementation status and deferred financial operations.
- `docs/02-ADR/ADR-067-FINANCING-OPERATION-IDEMPOTENCY.md` — idempotency principles.
- `docs/02-ADR/ADR-073-CREDIT-CARD-PAYMENT-AMOUNT-SELECTION.md` — current credit-card payment selection boundary.
- The Financial Engine single-writer ADR at `docs/02-ADR/ADR-007 Financial Engine is the only writer of Financial Truth..md`.

> **Numbering note:** The IFUP documents under `docs/New folder/` reuse ADR numbers that already exist in the active ADR set. The project reconciliation document treats copied/archived material there as historical unless explicitly adopted by an active document. This ADR is the canonical integration decision for SMS/IFUP V1; it does not bulk-promote, renumber, or silently adopt every historical ADR in that folder. Any such migration requires a separate reference-graph and semantic reconciliation.

## 1. Context

Wafferly needs to understand financial information from more than one input source, beginning with Android SMS and sharing the understanding layer with Voice. Understanding a message is not the same as establishing financial truth. The system must produce a reviewable financial proposal and must not write financial state directly from an adapter or AI model.

The agreed product direction is local-first: SQLite + Drift is intended to become the local source of truth, with optional cloud sync that is independent of SMS processing. The project snapshot reviewed for this decision still used Hive and did not yet contain the SMS/IFUP implementation; this ADR defines the target architecture, not completed implementation status.

## 2. Decision

### 2.1 Mandatory financial workflow

The production workflow is:

```text
Input Adapter
    -> Privacy Filter and Normalization
    -> Provider Registry / Known Templates
    -> IFUP / FinancialUnderstandingProvider
    -> Deterministic Validation and Matching
    -> Canonical Financial Draft or Clarification Request
    -> Local Review Queue
    -> User Confirm
    -> Draft-to-Command Mapper
    -> FinancialOperationEngine
    -> Atomic local persistence
```

- SMS and Voice each have their own adapter and source-specific handling.
- They share the understanding service, draft/review concepts, and the existing Financial Operation Engine.
- Regex/templates handle known, validated formats first. AI is part of MVP and handles unknown, changed, or ambiguous formats when an allowed model is available.
- Confidence alone never authorizes saving. Every transaction produced from SMS or Voice remains a proposal that the user must review and confirm.
- An adapter, parser, AI provider, or review screen must never write financial transactions or change balances directly.

### 2.2 Canonical draft boundary

`Canonical Financial Draft` is the contract used to map an understood and user-confirmed proposal into an existing financial command.

The draft must carry sufficient typed financial meaning to avoid confusing a mentioned amount with a completed event. It must support, where known:

- event type and direction;
- amount and currency;
- event time and merchant/payee;
- account hints and any required source/destination details;
- event status: `pending`, `posted`, `reversed`, or `unknown`;
- fields requiring clarification before a valid command can be created.

`eventStatus` and `eventType` are independent. For example, `reversed` is a status/state, not a purchase type. A message containing an amount does not by itself prove a final posted debit.

Source provenance (for example `originChannel = sms | voice | manual_paste`), parser version, confidence, evidence, session/process identifiers, and diagnostic metadata must be kept separate from financial-operation semantics. They may be retained alongside the review draft for traceability, but IFUP workflow internals and AI reasoning must not leak into the Financial Operation Engine contract. This preserves the context-free financial boundary defined by the existing IFUP design.

### 2.3 Event semantics and Voice intent

- `pending`: do not create a final posted transaction unless a separately accepted financial operation explicitly models the pending/reservation state.
- `posted`: may be mapped to a supported operation only after validation and user confirmation.
- `reversed`: do not treat as a new purchase or silently delete the original event; use the appropriate reversal/refund/correction operation only when that operation is supported and its policy is accepted.
- `unknown`: request clarification or manual review; do not guess.
- Credit-card purchase, payment, fee, installment, refund, and reversal are distinct event types.
- Voice understanding must distinguish past events, current commands, future intent, and unknown timing. “I will spend 300” is not evidence that a 300 expense has already occurred.
- A credit-card payment message may be detected and shown for review, but SMS must not enable a confirmed payment operation until the current implementation status, ADRs, and release checklist agree that the operation is supported.

### 2.4 Local source of truth and persistence boundary

- SQLite + Drift is the target local source of truth. Cloud sync is optional and is not required for SMS or local AI processing.
- SMS-specific persistence may include review drafts, message fingerprints/processing state, and versioned provider rules where needed.
- SMS must not create a parallel financial transaction table or separate balance model. Actual financial transactions remain in the existing canonical financial persistence model and are written only through `FinancialOperationEngine`.
- `originChannel` is provenance and must not overwrite or repurpose existing financial `source` semantics, especially credit-card, scheduled, and settlement sources.
- The Hive-to-Drift cutover is governed by `docs/02-ADR/ADR-075-HIVE-TO-SQLITE-DRIFT-MIGRATION.md`. Development of parsers, AI interfaces, and draft-only tests can proceed in parallel with that work.

### 2.5 Atomicity and production-save gate

No production SMS/Voice save flow may be enabled until all of the following are true:

1. The financial write path is using SQLite + Drift as approved by **ADR-075**.
2. The `UnitOfWork` provides real database-transaction atomicity; a memory-only wrapper is not sufficient.
3. Draft confirmation, financial mutation, and durable idempotency outcome are coordinated so interrupted execution cannot create a duplicate financial effect.
4. The temporary idempotency keys in the current planner are removed from production paths and replaced with stable operation identities.
5. Restart, failure, retry, concurrency, and restore tests demonstrate at-most-one financial effect for a logical operation.

A test-only repository may be used to develop and test understanding and review before this gate. It must not be mistaken for production financial persistence.

### 2.6 Three independent identities

| Identity | Responsibility |
|---|---|
| `messageFingerprint` | Detect repeat processing of the same input message. |
| `candidateId` | Track one draft and its review lifecycle. |
| `idempotencyKey` | Prevent a repeated execution attempt from creating a second financial effect for the same logical operation. |

`idempotencyKey` must remain stable across retries and must not be a temporary constant or a newly generated value for each attempt.

### 2.7 Message fingerprint protection and retention

- Use HMAC for message fingerprints with a local key protected by Android Keystore. Persist only the key/version identifier, never the key material or raw message text.
- Do not describe fingerprints as retained forever. Their retention must be at least as long as the maximum historical-message import window allowed by the product, plus a documented safety margin.
- The product must explicitly define the maximum historical-import age. If import is allowed from any date, time-limited fingerprints alone are insufficient; financial-transaction matching must also be applied before creating new candidates.
- When a fingerprint expires, is missing, or cannot be verified after restore/key loss, compare the candidate with existing financial transactions using multiple fields (for example account, provider, type, amount, time, and any available reference). Amount-only matching is not sufficient.
- A strong match is marked as already represented and must not create another financial effect. An uncertain match goes to manual review and is not auto-saved.
- Loss of an HMAC key may cause an old message to reappear as a candidate; it must never permit a duplicate financial save. Backup/restore behavior for the fingerprint registry must be explicit, and Keystore key material must not be copied in the database backup.

### 2.8 Draft lifecycle, retention, and local database protection

Every `Canonical Financial Draft` has an explicit lifecycle status. These statuses describe the proposal/review workflow, not the underlying financial event:

| Status | Meaning | Allowed outcome |
|---|---|---|
| `pending_review` | A draft has been created and is awaiting the user's decision. | User may edit, confirm, reject, or request clarification. |
| `needs_clarification` | Required meaning or fields are missing or contradictory. | Must be clarified or edited before it can be confirmed. |
| `confirmed_saved` | The financial operation succeeded and the resulting transaction reference is recorded. | Terminal for the draft; no second financial execution. |
| `rejected` | The user explicitly declined the proposal. | Terminal for the proposal; keep only the minimum tombstone/fingerprint metadata needed to prevent immediate re-prompting. |
| `matched_existing` | The proposal was matched to a transaction already represented in financial truth. | Terminal for the proposal; never create another financial effect. |
| `expired` | An unresolved proposal exceeded its review lifetime. | Terminal; remove unnecessary draft payload and do not save financially. |

A failed or interrupted confirmation must not mark the draft `confirmed_saved`. The financial mutation, durable idempotency outcome, and the transition to `confirmed_saved` must commit atomically under ADR-075. If the operation does not commit, the draft remains retryable and no partial financial state is allowed.

**Retention policy:**

- Proposed V1 default: unresolved drafts (`pending_review` or `needs_clarification`) expire 30 days after creation or last user interaction, whichever the final implementation policy selects. The exact clock rule and interval must be accepted before implementation freeze.
- At expiry, set `expired` and purge draft payload fields that are no longer needed, such as merchant text, free-form evidence, and redundant extracted details. Keep only minimum lifecycle metadata and the message fingerprint/tombstone needed under §2.7.
- After `confirmed_saved`, the canonical financial record is the authority. Remove redundant draft payload after the successful commit unless a documented operational requirement needs a limited retention period; preserve only the draft ID, final status, and transaction/operation reference as needed for traceability and idempotency.
- Rejected and `matched_existing` proposals must not retain full extracted payload longer than needed for user-visible history or duplicate suppression. Their minimal fingerprint/tombstone retention follows §2.7 and the selected historical-import policy.
- Fingerprint retention and draft-payload retention are separate policies. A draft may expire while its fingerprint remains valid for the historical-import window plus the documented safety margin. If import has no maximum age, transaction matching remains mandatory for older messages.

Drafts contain sensitive financial data even when raw SMS text is not retained. Store them only in the app-private local database, exclude them from logs, analytics, crash reports, and SMS/cloud sync, and apply the same access controls as other local financial data. SQLite/Drift alone must not be described as application-level database encryption. Before public release, explicitly decide and document database-at-rest protection; the recommended default is a maintained encrypted-SQLite solution (for example, a compatible SQLCipher integration) with its key protected by Android Keystore. Do not implement custom cryptography. If encryption is not adopted, document the threat-model rationale and obtain an explicit security exception before release.

### 2.9 Provider rules and personal learning

- A versioned Provider Registry holds provider-specific parsing rules for CIB, NBE, Banque Misr, Vodafone Cash, InstaPay, and later providers as validated.
- Default templates are developed from synthetic examples or sanitized examples collected with appropriate permission. Test cases must include positive examples and negative/contradictory cases (for example debit versus credit, refund/reversal, pending versus posted, unexpected amount/currency, and non-financial messages).
- If a template conflicts with message semantics, it is not applied blindly; the message is sent to AI if allowed or routed to review/clarification.
- A user-specific `Personal Template Candidate` may be learned locally, but repeated user confirmations are only a quality signal, not proof of correctness. It must pass consistency checks and negative tests before becoming active. A detected contradiction disables or demotes the template.
- Every message still generates its own reviewable proposal; a learned template never bypasses `Suggest -> Confirm -> Save`.
- Cross-user learning from production SMS/Voice content is out of scope for V1. Personal templates remain on the user's device. Shared templates are authored and validated by the team; a contributor count (such as five users) is not a privacy or compliance guarantee.

### 2.10 AI provider and privacy policy

- AI is part of MVP, but it is not required to run for every message. Known validated formats may use local deterministic templates; unfamiliar cases use `FinancialUnderstandingProvider` when permitted processing is available.
- On-device AI is preferred when the selected model is supported and meets tested Arabic SMS quality, latency, and device requirements. Do not assume any specific model is available or accurate on every supported Android device.
- Cloud AI is optional, disabled by default, and independent of cloud sync and SMS-read permission. Consent must be explicit, scoped, understandable, and revocable.
- For batch import, one confirmation may cover a clearly described batch when the consent screen shows the number of messages potentially sent and the categories of data sent after minimization. Live processing must clearly disclose that unfamiliar messages may be sent under the active permission and must allow the user to turn cloud analysis off.
- Send only the minimum data needed for one unresolved message, not the user's entire message history. Redaction reduces risk but does not guarantee anonymization.
- Before enabling a cloud provider, review contractual and technical terms for retention, deletion, human review, processing location, and training use. Wafferly customer inputs must not be used to train the provider's models unless separately reviewed and lawfully authorized.
- Raw SMS text is transient, must not be persisted as a normal application record, must not appear in logs/analytics/crash reports, and must not be sent to cloud sync.
- If no suitable local model is available and the user has not consented to cloud AI, the app must say that this message could not be automatically understood and leave manual review/entry available. Do not imply full automatic understanding is available in this state.

### 2.11 Google Play release boundary

- Google Play is the primary distribution target. SMS-read permission approval is an open release gate and must not be assumed from the existence of similar apps.
- Every submitted build, Play Console declaration, privacy disclosure, Data Safety answer, and runtime behavior must match. This ADR does not authorize hiding functionality from a reviewer or misrepresenting the submitted build.
- Under the current release plan, the first submitted build targets automatic SMS discovery and does not include the manual paste/share message adapter. This is a build-scope decision, not a way to conceal a feature that is present.
- If SMS permission/exemption is denied or no longer available, prepare a later Play build without SMS-read permissions and add user-selected paste/share input only after reviewing that flow's policy and disclosure requirements. Do not use paste/share to bypass a denial in a way that continues to read the inbox without permission.
- If the user declines SMS permission, ordinary Wafferly functionality and manual transaction entry remain usable; automatic SMS discovery is unavailable.
- Confirm the policy applicable at submission time through Play Console or Google developer support. Any report about a future policy draft remains unverified until confirmed directly.

## 3. Consequences

### Positive

- SMS and Voice share one understanding and financial-draft contract rather than implementing separate financial write paths.
- AI can handle unknown formats while deterministic checks protect financial semantics.
- Local-first behavior remains possible without cloud sync or mandatory cloud AI.
- The financial engine and local database remain the sole path for authoritative financial effects.
- Draft-only work can progress in parallel with the storage migration.

### Costs and limitations

- The first implementation requires a carefully curated test corpus and device-level AI tests.
- Users without a suitable local model who decline cloud AI will not receive automatic understanding for all unfamiliar messages.
- Google Play approval for SMS permissions remains uncertain until the actual submission is reviewed.
- Message re-import and key-restore behavior requires explicit tests; fingerprints alone do not solve transaction-level duplicates.

## 4. Required Validation Tests

1. Known-format SMS parses into a draft without saving a transaction.
2. Unknown format calls the permitted AI provider or yields clarification when AI is unavailable.
3. Arabic and English digits, separators, currencies, and provider-specific variants normalize correctly.
4. OTP, advertisements, and non-financial messages are excluded from financial parsing.
5. Pending, posted, reversed, and unknown event statuses are not conflated.
6. Voice past-event statements are distinguished from future intentions and commands.
7. User edit, clarification, rejection, expiration, match-to-existing, and confirmation follow only allowed draft lifecycle transitions.
8. A draft cannot reach `confirmed_saved` unless the financial operation and durable idempotency outcome commit successfully.
9. Expired/rejected drafts purge unnecessary payload while retaining only policy-approved duplicate-suppression metadata.
10. Draft-payload retention and message-fingerprint retention are tested independently.
11. The same message re-imported within the fingerprint window is not processed twice.
12. Re-import after fingerprint expiry or HMAC-key loss matches against existing financial transactions before creating a new candidate.
13. Similar amount alone does not count as a conclusive transaction match.
14. Repeated confirmation or template learning never bypasses per-transaction review.
15. A confirmed logical operation retried after interruption or concurrency produces at most one financial effect.
16. No SMS/IFUP component writes directly to financial transaction or balance persistence.
17. No raw SMS text appears in persistent logs, analytics, crash reports, or cloud sync.
18. Cloud AI consent is distinct from SMS permission and cloud-sync consent, can be revoked, and follows the disclosed scope.
19. Draft database protection and encryption/exception decisions are documented and tested according to the release policy.
20. Credit-card payment messages cannot be saved as confirmed financial operations until the operation is explicitly supported by implementation and accepted documentation.

## 5. Deferred / Open Decisions

The following are not settled by this ADR and must be resolved before release where applicable:

1. Exact Google Play policy/exemption status at submission time.
2. Supported Android device range and measured local-model quality for Egyptian Arabic/English provider messages.
3. Cloud AI provider, retention/deletion terms, processing location, and training policy.
4. The product maximum age for historical SMS import and corresponding fingerprint-retention duration plus safety margin.
5. The clean Hive-to-Drift cutover in `ADR-075`, the actual Drift-backed UnitOfWork, and its atomicity/idempotency acceptance tests.
6. The current release status and accepted financial operation for credit-card payments, settlement, refunds, and reversals before mapping corresponding messages to executable commands.
7. Final unresolved-draft TTL (30 days is the proposed V1 default) and exact policy for deleting minimal rejected/expired draft metadata.
8. The local database-at-rest encryption decision and implementation proof before public release.
9. Any future cross-user learning, which requires separate policy/legal review and a new ADR; it is not part of V1.

## Final Decision

This ADR establishes the canonical V1 integration boundary for SMS and IFUP: source adapters and AI produce a reviewable financial draft; the user confirms it; and only the existing `FinancialOperationEngine` may create authoritative financial effects. Development of understanding and draft tests may proceed in parallel with the SQLite + Drift migration, but production saving remains blocked until atomic persistence and durable idempotency gates pass. This is an architecture decision, not evidence that the feature has been implemented or approved for Google Play.
