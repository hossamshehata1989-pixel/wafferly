# Wafferly — AI Architecture (Canonical Reference)

**Status:** Architecture reference; implementation is not yet complete  
**Date:** 2026-10-13  
**Canonical project path:** `docs/01-architecture/AI Architecture.md`  
**Normative decisions:** `docs/02-ADR/ADR-074-SMS-IFUP-V1-INTEGRATION.md` and `docs/02-ADR/ADR-075-HIVE-TO-SQLITE-DRIFT-MIGRATION.md`

This file is the high-level map for AI/IFUP decisions. It summarizes, but does not override, the related ADRs. If the code and documents differ, implementation status must be described honestly and the ADRs reconciled before treating a capability as implemented.

## 1. Goals and boundaries

Wafferly uses AI to understand financial inputs, not to establish financial truth. SMS, Voice, and any future input channel can produce a `Canonical Financial Draft`; only the user-confirmed command routed through `FinancialOperationEngine` may create authoritative financial effects.

Required workflow:

```text
SMS Adapter ──────┐
                  ├─> Normalize/Filter -> IFUP -> Validate/Match
Voice Adapter ────┘                         -> Canonical Financial Draft
                                            -> Local Review Queue
                                            -> User Confirm
                                            -> Draft-to-Command Mapper
                                            -> FinancialOperationEngine
                                            -> SQLite + Drift transaction
```

SMS and Voice have independent adapters because source evidence and intent differ. They share financial understanding, draft representation, review states, validation, and the financial execution boundary.

## 2. Hybrid understanding strategy

- Known, validated provider formats use deterministic templates/Regex first.
- AI is part of MVP and handles unknown, changed, or ambiguous formats when an allowed model is available.
- Local/on-device AI is preferred only when the model is supported on the device and achieves measured quality for Egyptian Arabic and English financial messages.
- Cloud AI is an optional separate capability, disabled by default, unrelated to cloud sync and unrelated to SMS permission. It needs explicit, scoped, revocable consent.
- If local AI is unavailable or unsuitable and the user has not consented to cloud AI, the app must ask for clarification or provide manual entry; it must not pretend that automatic understanding succeeded.
- `FinancialUnderstandingProvider` abstracts the selected model/provider so the product is not locked to one model or assumed device capability.

## 3. Canonical Financial Draft

The draft is a typed proposal, not a financial transaction. It carries only data needed for review and command mapping, which may include:

- event type and direction;
- amount and currency;
- event time, merchant/payee, and account hints;
- `eventStatus`: `pending`, `posted`, `reversed`, or `unknown`;
- source provenance such as `originChannel = sms | voice | manual_paste`;
- parser/template version, confidence, and unresolved required fields.

`eventStatus` is distinct from `eventType`. `reversed` is not a purchase type; an amount in a message does not alone prove a posted debit. Unsupported or ambiguous cases require clarification and must not be guessed into a save command.

For Voice, distinguish past-event claims, present commands, future intentions, and unknown timing. “I will spend 300” is not evidence that an expense already occurred. SMS often describes a financial event from the provider's perspective but may still reflect a pending authorization, reversal, refund, fee, or settlement requiring correct semantics and review.

## 4. Draft lifecycle

The V1 lifecycle statuses are:

| Status | Meaning |
|---|---|
| `pending_review` | Parsed proposal is awaiting the user's decision. |
| `needs_clarification` | Data or meaning is missing or contradictory; cannot be confirmed until resolved. |
| `confirmed_saved` | The operation committed successfully through the Financial Engine; includes the final transaction/operation reference. |
| `rejected` | The user declined the proposal. |
| `matched_existing` | The proposal is already represented by existing financial truth; no new transaction is written. |
| `expired` | An unresolved proposal exceeded its retention window and its unnecessary payload was purged. |

A failed or interrupted save must not produce `confirmed_saved`. The transaction, durable idempotency outcome, and final draft status are coordinated atomically according to ADR-075. The UI can keep a failed confirmation retryable without claiming the transaction was saved.

### Draft retention and storage

- Proposed V1 default: unresolved drafts expire after 30 days. The exact timer rule and interval must be accepted before implementation freeze.
- At expiration, purge unnecessary draft fields such as merchant/evidence text; retain only minimum lifecycle and duplicate-suppression metadata under ADR-074's fingerprint rules.
- After successful save, the financial transaction is authoritative; purge redundant draft payload when no longer needed, retaining only minimum traceability/linkage required by the implementation.
- Draft payload and message-fingerprint retention are separate. Fingerprints must be retained at least as long as the maximum historical import window plus a safety margin; older/unbounded imports require transaction matching, not fingerprints alone.
- Drafts are sensitive financial data. Store them only in app-private local storage, and exclude raw SMS and sensitive draft values from logs, analytics, crash reports, and cloud sync.
- SQLite/Drift is not inherently application-level encrypted. Choose and document the at-rest protection before public release. The recommended default is a maintained encrypted-SQLite solution with key material protected by Android Keystore; do not create custom cryptography.

## 5. Provider Registry and learning

- Provider-specific templates are versioned and kept separate for CIB, NBE, Banque Misr, Vodafone Cash, InstaPay, and additional providers after validation.
- Initial shared templates are authored by the team from synthetic or appropriately sanitized/consented examples and are tested against both positive and negative cases.
- A personal template candidate can be learned locally but is not promoted solely because a user confirmed similar transactions multiple times. It must pass consistency checks and negative test cases (direction, amount, currency, status, refund/reversal, and non-financial content).
- If a template contradicts the message, disable/demote it and route to permitted AI or clarification/review.
- Every input still produces a separate proposal and user review. Templates never bypass `Suggest -> Confirm -> Save`.
- Cross-user learning from production SMS or Voice content is out of scope for V1. Shared templates are team-authored/validated unless a future ADR and policy/legal review explicitly authorize another mechanism.

## 6. Privacy and provider boundaries

- Raw SMS text exists only temporarily in the parsing flow, is not persisted as a normal record, and must not be written to logs/analytics/crash reports.
- Local understanding is preferred. SMS text and fingerprints do not go to cloud sync.
- Cloud AI is disabled by default and requires separate consent, independent from SMS-read permission and financial cloud-sync consent.
- For batch import, one clear confirmation may cover a batch if the screen explains how many messages may be sent, what fields/categories are sent after minimization, the model/provider purpose, and the relevant retention/training terms. Live processing needs a clear disclosure of the active behavior and an easy way to disable cloud analysis.
- Send only the minimum necessary data for one unresolved message. Redaction reduces risk but does not guarantee anonymization.
- Before enabling a cloud provider, review retention/deletion, processing location, human review, and model-training terms. Do not enable customer-data training by default.

## 7. Privacy-safe message fingerprinting

- Fingerprint messages with HMAC using a local key protected by Android Keystore. Store a key-version identifier, not the key material.
- Fingerprint retention must be at least the maximum permitted historical import window plus a documented safety margin.
- If a fingerprint expires, disappears, or cannot be verified after key loss/restore, compare against existing confirmed financial transactions using multiple fields. Amount-only matching is insufficient.
- Strong matches become `matched_existing`; ambiguous matches require review. Neither may automatically create a duplicate financial effect.
- A restored database without the original Keystore key must not be treated as proof that old SMS has never been processed.

## 8. Platform/release constraints

- Android SMS auto-discovery is the V1 target, subject to Google Play permission/exemption approval.
- The submitted binary, Play Console declarations, privacy disclosures, and runtime behavior must match.
- If SMS permissions are denied or unavailable, use a Play build without inbox-reading permissions and add user-selected paste/share input only after policy review; never use an alternate path to continue reading the inbox without permission.
- If the user declines SMS permission, Wafferly's ordinary financial features and manual entry remain available.
- Do not claim that local AI is available on every Android device; verify device/model capability and quality on representative Egyptian Arabic/English message tests.

## 9. Required implementation gates

1. Complete the project ADR reconciliation; this reference does not promote historical ADRs by implication.
2. Build the draft-only understanding path and test corpus in parallel with Drift work.
3. Complete SQLite + Drift repositories, real transactional `UnitOfWork`, and stable idempotency before enabling production save.
4. Pass parser/AI tests, financial semantic tests, re-import/fingerprint tests, draft lifecycle/retention tests, and restart/concurrency tests.
5. Resolve the database-at-rest security decision before public release.
6. Verify current Google Play SMS policy/exemption and the supported AI-provider privacy terms before release.

## 10. Implementation status

This document defines the architecture. It does not prove that SMS reading, IFUP, AI providers, SQLite/Drift storage, encryption, or the final review/save flow has been implemented. Current implementation status must be verified against the complete latest Flutter repository and its tests.
